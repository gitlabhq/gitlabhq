import { uniqueId } from 'lodash-es';
import { NodeSelection } from '@tiptap/pm/state';
import { VARIANT_DANGER } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __, sprintf } from '~/locale';
import { bytesToMiB } from '~/lib/utils/number_utils';
import { getLimitedMediaDimensions } from '~/lib/utils/media_utils';
import TappablePromise from '~/lib/utils/tappable_promise';
import { ALERT_EVENT } from '../constants';

const chain = (editor) => editor.chain().setMeta('preventAutolink', true);

// every occurrence of an upload placeholder in document order: media nodes
// carry the file id in their attrs, attachment text carries it on its link
// mark. `descendants` keeps walking after a match, so collect instead of
// returning early; every copy of a placeholder must resolve with the upload
const findUploadedFileOccurrences = (editor, fileId) => {
  const occurrences = [];

  editor.view.state.doc.descendants((node, position) => {
    const isPlaceholder =
      node.attrs.uploading === fileId ||
      node.marks.some((mark) => mark.type.name === 'link' && mark.attrs.uploading === fileId);

    if (isPlaceholder) occurrences.push({ node, position });
  });

  return occurrences;
};

// patches every occurrence in one transaction (leaf nodes keep their size, so
// the positions hold); a node selection sitting on one of them is restored
// because it does not survive setNodeMarkup mapping
const updateUploadedNodeAttrs = ({ editor, occurrences, attrs }) => {
  const { selection } = editor.state;
  const tr = editor.state.tr.setMeta('preventAutolink', true);
  let selectedPosition;

  occurrences.forEach(({ node, position }) => {
    if (selection.node === node && selection.from === position) selectedPosition = position;

    tr.setNodeMarkup(position, undefined, { ...node.attrs, ...attrs });
  });

  if (selectedPosition !== undefined) {
    tr.setSelection(NodeSelection.create(tr.doc, selectedPosition));
  }

  editor.view.dispatch(tr);
};

// removes every occurrence in one transaction, later ones first so the
// earlier positions stay valid
const deleteUploadedFileOccurrences = (editor, occurrences) => {
  const tr = editor.state.tr.setMeta('preventAutolink', true);

  [...occurrences].reverse().forEach(({ node, position }) => {
    tr.delete(position, position + node.nodeSize);
  });

  editor.view.dispatch(tr);
};

export const acceptedMimes = {
  drawioDiagram: {
    mimes: ['image/svg+xml'],
    ext: 'drawio.svg',
  },
  image: {
    mimes: [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/svg+xml',
      'image/webp',
      'image/tiff',
      'image/bmp',
      'image/vnd.microsoft.icon',
      'image/x-icon',
    ],
  },
  audio: {
    mimes: [
      'audio/basic',
      'audio/mid',
      'audio/mpeg',
      'audio/x-aiff',
      'audio/ogg',
      'audio/vorbis',
      'audio/vnd.wav',
    ],
  },
  video: {
    mimes: ['video/mp4', 'video/quicktime'],
  },
};

const extractAttachmentLinkUrl = (html) => {
  const parser = new DOMParser();
  const { body } = parser.parseFromString(html, 'text/html');

  // Try to find a link first (for attachments)
  const element =
    body.querySelector('a') ||
    body.querySelector('img') ||
    body.querySelector('video') ||
    body.querySelector('audio');

  const src = element?.getAttribute('href') || element?.getAttribute('src');
  const { canonicalSrc } = element?.dataset || {};

  return { src, canonicalSrc };
};

class UploadError extends Error {}

const notifyUploadError = (eventHub, error) => {
  eventHub.$emit(ALERT_EVENT, {
    message:
      error instanceof UploadError
        ? error.message
        : __('An error occurred while uploading the file. Please try again.'),
    variant: VARIANT_DANGER,
  });
};

/**
 * Uploads a file with a post request to the URL indicated
 * in the uploadsPath parameter. The expected response of the
 * uploads service is a JSON object that contains, at least, a
 * link property. The link property should contain markdown link
 * definition (i.e. [GitLab](https://gitlab.com)).
 *
 * This Markdown will be rendered to extract its canonical and full
 * URLs using GitLab Flavored Markdown renderer in the backend.
 *
 * @param {Object} params
 * @param {String} params.uploadsPath An absolute URL that points to a service
 * that allows sending a file for uploading via POST request.
 * @param {String} params.renderMarkdown A function that accepts a markdown string
 * and returns a rendered version in HTML format.
 * @param {File} params.file The file to upload
 *
 * @returns {TappablePromise} Returns an object with two properties:
 *
 * canonicalSrc: The URL as defined in the Markdown
 * src: The absolute URL that points to the resource in the server
 */
export const uploadFile = ({ uploadsPath, renderMarkdown, file }) => {
  return new TappablePromise(async (tap) => {
    const maxFileSize = (gon.max_file_size || 10).toFixed(0);
    const fileSize = bytesToMiB(file.size);
    if (fileSize > maxFileSize) {
      throw new UploadError(
        sprintf(__('File is too big (%{fileSize}MiB). Max filesize: %{maxFileSize}MiB.'), {
          fileSize: fileSize.toFixed(2),
          maxFileSize,
        }),
      );
    }

    const formData = new FormData();
    formData.append('file', file, file.name);

    const { data } = await axios.post(uploadsPath, formData, {
      onUploadProgress: (e) => tap(e.loaded / e.total),
    });
    const { markdown } = data.link;
    const { body: rendered } = await renderMarkdown(markdown);

    return extractAttachmentLinkUrl(rendered);
  });
};

export const uploadingStates = {};

const uploadMedia = async ({ type, editor, file, uploadsPath, renderMarkdown, eventHub }) => {
  // needed to avoid mismatched transaction error
  await Promise.resolve();

  const objectUrl = URL.createObjectURL(file);
  const { selection } = editor.view.state;
  const currentNode = selection.$to.node();
  const fileId = uniqueId(type);

  const position = selection.to;
  let content = {
    type,
    attrs: { uploading: fileId, src: objectUrl, alt: file.name },
  };
  let selectionIncrement = 0;
  getLimitedMediaDimensions(file)
    .then(({ width, height } = {}) => {
      if (!width || !height) return;

      // Target the node by its fileId rather than the current selection, which
      // may have moved to a subsequently dropped media before this resolves.
      const occurrences = findUploadedFileOccurrences(editor, fileId);
      if (!occurrences.length) return;

      updateUploadedNodeAttrs({ editor, occurrences, attrs: { width, height } });
    })
    .catch(() => {});

  // if the current node is not empty, we need to wrap the content in a new paragraph
  if (currentNode.content.size > 0 || currentNode.type.name === 'doc') {
    content = {
      type: 'paragraph',
      content: [content],
    };
    selectionIncrement = 1;
  }

  chain(editor)
    .insertContentAt(position, content)
    .setNodeSelection(position + selectionIncrement)
    .run();

  uploadFile({ file, uploadsPath, renderMarkdown })
    .tap((progress) => {
      chain(editor).setMeta('uploadProgress', { uploading: fileId, progress }).run();
    })
    .then(({ canonicalSrc, src }) => {
      // the position might have changed while uploading, so we need to find it again
      const occurrences = findUploadedFileOccurrences(editor, fileId);

      uploadingStates[fileId] = true;

      // placeholder deleted mid-upload: discard the upload result
      if (!occurrences.length) return;

      updateUploadedNodeAttrs({
        editor,
        occurrences,
        attrs: { uploading: false, src, alt: file.name, canonicalSrc },
      });
    })
    .catch((e) => {
      const occurrences = findUploadedFileOccurrences(editor, fileId);

      if (occurrences.length) deleteUploadedFileOccurrences(editor, occurrences);

      notifyUploadError(eventHub, e);
    });
};

const uploadAttachment = async ({ editor, file, uploadsPath, renderMarkdown, eventHub }) => {
  // needed to avoid mismatched transaction error
  await Promise.resolve();

  const objectUrl = URL.createObjectURL(file);
  const { selection } = editor.view.state;
  const currentNode = selection.$to.node();
  const fileId = uniqueId('file');

  uploadingStates[fileId] = true;

  const position = selection.to;
  let content = {
    type: 'text',
    text: file.name,
    marks: [{ type: 'link', attrs: { href: objectUrl, uploading: fileId } }],
  };

  // if the current node is not empty, we need to wrap the content in a new paragraph
  if (currentNode.content.size > 0 || currentNode.type.name === 'doc') {
    content = {
      type: 'paragraph',
      content: [content],
    };
  }

  chain(editor).insertContentAt(position, content).extendMarkRange('link').run();

  uploadFile({ file, uploadsPath, renderMarkdown })
    .tap((progress) => {
      chain(editor).setMeta('uploadProgress', { filename: file.name, progress }).run();
    })
    .then(({ src, canonicalSrc }) => {
      // the position might have changed while uploading, so we need to find it again
      const occurrences = findUploadedFileOccurrences(editor, fileId);

      // placeholder link deleted mid-upload: discard the upload result
      if (!occurrences.length) return;

      // styling or edits may have split the link into several text nodes;
      // each carries the mark, so each is patched
      const tr = editor.state.tr.setMeta('preventAutolink', true);

      occurrences.forEach(({ node, position: from }) => {
        const linkMark = node.marks.find((mark) => mark.type.name === 'link');

        tr.addMark(
          from,
          from + node.nodeSize,
          linkMark.type.create({ ...linkMark.attrs, href: src, canonicalSrc, uploading: false }),
        );
      });

      editor.view.dispatch(tr);
    })
    .catch((e) => {
      const occurrences = findUploadedFileOccurrences(editor, fileId);

      if (occurrences.length) deleteUploadedFileOccurrences(editor, occurrences);

      notifyUploadError(eventHub, e);
    });
};

export const handleFileEvent = ({ editor, file, uploadsPath, renderMarkdown, eventHub }) => {
  if (!file) return false;

  for (const [type, { mimes, ext }] of Object.entries(acceptedMimes)) {
    if (mimes.includes(file?.type) && (!ext || file?.name.endsWith(ext))) {
      uploadMedia({ type, editor, file, uploadsPath, renderMarkdown, eventHub });

      return true;
    }
  }

  uploadAttachment({ editor, file, uploadsPath, renderMarkdown, eventHub });

  return true;
};

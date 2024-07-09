import { uniqueId } from 'lodash';
import { VARIANT_DANGER } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __, sprintf } from '~/locale';
import { bytesToMiB } from '~/lib/utils/number_utils';
import { getRetinaDimensions } from '~/lib/utils/image_utils';
import TappablePromise from '~/lib/utils/tappable_promise';
import { ALERT_EVENT } from '../constants';

const chain = (editor) => editor.chain().setMeta('preventAutolink', true);

const findUploadedFilePosition = (editor, fileId) => {
  let position;
  let node;

  editor.view.state.doc.descendants((descendant, pos) => {
    if (descendant.attrs.uploading === fileId) {
      position = pos;
      node = descendant;
      return false;
    }

    for (const mark of descendant.marks) {
      if (mark.type.name === 'link' && mark.attrs.uploading === fileId) {
        position = pos + 1;
        node = descendant;
        return false;
      }
    }

    return true;
  });

  return { position, node };
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
  const link = body.querySelector('a');
  const src = link.getAttribute('href');
  const { canonicalSrc } = link.dataset;

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

  let position = selection.to;
  let node;
  let content = {
    type,
    attrs: { uploading: fileId, src: objectUrl, alt: file.name },
  };
  let selectionIncrement = 0;
  getRetinaDimensions(file)
    .then(({ width, height } = {}) => {
      if (width && height) {
        chain(editor).updateAttributes(type, { width, height }).run();
      }
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
    .then(({ canonicalSrc }) => {
      // the position might have changed while uploading, so we need to find it again
      ({ node, position } = findUploadedFilePosition(editor, fileId));

      uploadingStates[fileId] = true;

      editor.view.dispatch(
        editor.state.tr.setMeta('preventAutolink', true).setNodeMarkup(position, undefined, {
          ...node.attrs,
          uploading: false,
          src: objectUrl,
          alt: file.name,
          canonicalSrc,
        }),
      );

      chain(editor).setNodeSelection(position).run();
    })
    .catch((e) => {
      ({ position } = findUploadedFilePosition(editor, fileId));

      chain(editor)
        .deleteRange({ from: position, to: position + 1 })
        .run();

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

  let position = selection.to;
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
      ({ position } = findUploadedFilePosition(editor, fileId));

      chain(editor)
        .setTextSelection(position)
        .extendMarkRange('link')
        .updateAttributes('link', { href: src, canonicalSrc, uploading: false })
        .run();
    })
    .catch((e) => {
      ({ position } = findUploadedFilePosition(editor, fileId));

      chain(editor)
        .setTextSelection(position)
        .extendMarkRange('link')
        .unsetLink()
        .deleteSelection()
        .run();

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

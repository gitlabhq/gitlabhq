import { VARIANT_DANGER } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { extractFilename, readFileAsDataURL } from './utils';

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
 * @returns Returns an object with two properties:
 *
 * canonicalSrc: The URL as defined in the Markdown
 * src: The absolute URL that points to the resource in the server
 */
export const uploadFile = async ({ uploadsPath, renderMarkdown, file }) => {
  const formData = new FormData();
  formData.append('file', file, file.name);

  const { data } = await axios.post(uploadsPath, formData);
  const { markdown } = data.link;
  const rendered = await renderMarkdown(markdown);

  return extractAttachmentLinkUrl(rendered);
};

const uploadContent = async ({ type, editor, file, uploadsPath, renderMarkdown, eventHub }) => {
  const encodedSrc = await readFileAsDataURL(file);
  const { view } = editor;

  editor.commands.insertContent({ type, attrs: { uploading: true, src: encodedSrc } });

  const { state } = view;
  const position = state.selection.from - 1;
  const { tr } = state;

  editor.commands.setNodeSelection(position);

  try {
    const { src, canonicalSrc } = await uploadFile({ file, uploadsPath, renderMarkdown });

    view.dispatch(
      tr.setNodeMarkup(position, undefined, {
        uploading: false,
        src: encodedSrc,
        alt: extractFilename(src),
        canonicalSrc,
      }),
    );

    editor.commands.setNodeSelection(position);
  } catch (e) {
    editor.commands.deleteRange({ from: position, to: position + 1 });
    eventHub.$emit('alert', {
      message: __('An error occurred while uploading the file. Please try again.'),
      variant: VARIANT_DANGER,
    });
  }
};

const uploadAttachment = async ({ editor, file, uploadsPath, renderMarkdown, eventHub }) => {
  await Promise.resolve();

  const { view } = editor;

  const text = extractFilename(file.name);

  const { state } = view;
  const { from } = state.selection;

  editor.commands.insertContent({
    type: 'loading',
    attrs: { label: text },
  });

  try {
    const { src, canonicalSrc } = await uploadFile({ file, uploadsPath, renderMarkdown });

    editor.commands.insertContentAt(
      { from, to: from + 1 },
      { type: 'text', text, marks: [{ type: 'link', attrs: { href: src, canonicalSrc } }] },
    );
  } catch (e) {
    editor.commands.deleteRange({ from, to: from + 1 });
    eventHub.$emit('alert', {
      message: __('An error occurred while uploading the file. Please try again.'),
      variant: VARIANT_DANGER,
    });
  }
};

export const handleFileEvent = ({ editor, file, uploadsPath, renderMarkdown, eventHub }) => {
  if (!file) return false;

  for (const [type, { mimes, ext }] of Object.entries(acceptedMimes)) {
    if (mimes.includes(file?.type) && (!ext || file?.name.endsWith(ext))) {
      uploadContent({ type, editor, file, uploadsPath, renderMarkdown, eventHub });

      return true;
    }
  }

  uploadAttachment({ editor, file, uploadsPath, renderMarkdown, eventHub });

  return true;
};

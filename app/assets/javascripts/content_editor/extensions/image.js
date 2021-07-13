import { Image } from '@tiptap/extension-image';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import { Plugin, PluginKey } from 'prosemirror-state';
import { __ } from '~/locale';
import ImageWrapper from '../components/wrappers/image.vue';
import { uploadFile } from '../services/upload_file';
import { getImageAlt, readFileAsDataURL } from '../services/utils';

export const acceptedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/jpg'];

const resolveImageEl = (element) =>
  element.nodeName === 'IMG' ? element : element.querySelector('img');

const startFileUpload = async ({ editor, file, uploadsPath, renderMarkdown }) => {
  const encodedSrc = await readFileAsDataURL(file);
  const { view } = editor;

  editor.commands.setImage({ uploading: true, src: encodedSrc });

  const { state } = view;
  const position = state.selection.from - 1;
  const { tr } = state;

  try {
    const { src, canonicalSrc } = await uploadFile({ file, uploadsPath, renderMarkdown });

    view.dispatch(
      tr.setNodeMarkup(position, undefined, {
        uploading: false,
        src: encodedSrc,
        alt: getImageAlt(src),
        canonicalSrc,
      }),
    );
  } catch (e) {
    editor.commands.deleteRange({ from: position, to: position + 1 });
    editor.emit('error', __('An error occurred while uploading the image. Please try again.'));
  }
};

const handleFileEvent = ({ editor, file, uploadsPath, renderMarkdown }) => {
  if (acceptedMimes.includes(file?.type)) {
    startFileUpload({ editor, file, uploadsPath, renderMarkdown });

    return true;
  }

  return false;
};

const ExtendedImage = Image.extend({
  defaultOptions: {
    ...Image.options,
    uploadsPath: null,
    renderMarkdown: null,
  },
  addAttributes() {
    return {
      ...this.parent?.(),
      uploading: {
        default: false,
      },
      src: {
        default: null,
        /*
         * GitLab Flavored Markdown provides lazy loading for rendering images. As
         * as result, the src attribute of the image may contain an embedded resource
         * instead of the actual image URL. The image URL is moved to the data-src
         * attribute.
         */
        parseHTML: (element) => {
          const img = resolveImageEl(element);

          return {
            src: img.dataset.src || img.getAttribute('src'),
          };
        },
      },
      canonicalSrc: {
        default: null,
        parseHTML: (element) => {
          return {
            canonicalSrc: element.dataset.canonicalSrc,
          };
        },
      },
      alt: {
        default: null,
        parseHTML: (element) => {
          const img = resolveImageEl(element);

          return {
            alt: img.getAttribute('alt'),
          };
        },
      },
    };
  },
  parseHTML() {
    return [
      {
        priority: 100,
        tag: 'a.no-attachment-icon',
      },
      {
        tag: 'img[src]',
      },
    ];
  },
  addCommands() {
    return {
      ...this.parent(),
      uploadImage: ({ file }) => () => {
        const { uploadsPath, renderMarkdown } = this.options;

        handleFileEvent({ file, uploadsPath, renderMarkdown, editor: this.editor });
      },
    };
  },
  addProseMirrorPlugins() {
    const { editor } = this;

    return [
      new Plugin({
        key: new PluginKey('handleDropAndPasteImages'),
        props: {
          handlePaste: (_, event) => {
            const { uploadsPath, renderMarkdown } = this.options;

            return handleFileEvent({
              editor,
              file: event.clipboardData.files[0],
              uploadsPath,
              renderMarkdown,
            });
          },
          handleDrop: (_, event) => {
            const { uploadsPath, renderMarkdown } = this.options;

            return handleFileEvent({
              editor,
              file: event.dataTransfer.files[0],
              uploadsPath,
              renderMarkdown,
            });
          },
        },
      }),
    ];
  },
  addNodeView() {
    return VueNodeViewRenderer(ImageWrapper);
  },
});

const serializer = (state, node) => {
  const { alt, canonicalSrc, src, title } = node.attrs;
  const quotedTitle = title ? ` ${state.quote(title)}` : '';

  state.write(`![${state.esc(alt || '')}](${state.esc(canonicalSrc || src)}${quotedTitle})`);
};

export const configure = ({ renderMarkdown, uploadsPath }) => {
  return {
    tiptapExtension: ExtendedImage.configure({ inline: true, renderMarkdown, uploadsPath }),
    serializer,
  };
};

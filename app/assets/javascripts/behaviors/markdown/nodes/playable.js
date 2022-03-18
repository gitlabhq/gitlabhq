import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';

/**
 * Abstract base class for playable media, like video and audio.
 * Must not be instantiated directly. Subclasses must set
 * the `mediaType` property in their constructors.
 * @abstract
 */
export default ({ mediaType, extraElementAttrs = {} }) => {
  const attrs = {
    src: {},
    alt: {
      default: null,
    },
  };
  const parseDOM = [
    {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      tag: `.${mediaType}-container`,
      getAttrs: (el) => ({
        src: el.querySelector(mediaType).src,
        alt: el.querySelector(mediaType).dataset.title,
      }),
    },
  ];
  const toDOM = (node) => [
    'span',
    { class: `media-container ${mediaType}-container` },
    [
      mediaType,
      {
        src: node.attrs.src,
        controls: true,
        'data-setup': '{}',
        'data-title': node.attrs.alt,
        ...extraElementAttrs,
      },
    ],
    ['a', { href: node.attrs.src }, node.attrs.alt],
  ];

  return {
    name: mediaType,
    schema: {
      attrs,
      group: 'inline',
      inline: true,
      draggable: true,
      parseDOM,
      toDOM,
    },
    toMarkdown(state, node) {
      defaultMarkdownSerializer.nodes.image(state, node);
    },
  };
};

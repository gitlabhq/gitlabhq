import { builders } from 'prosemirror-test-builder';
import createMarkdownDeserializer from '~/content_editor/services/gl_api_markdown_deserializer';
import MarkdownSerializer from '~/content_editor/services/markdown_serializer';
import { createTiptapEditor } from './test_utils';
/**
 * @import { Node, Mark } from '@tiptap/pm/model';
 */

jest.mock('~/emoji');

export const tiptapEditor = createTiptapEditor([]);
const { doc, ...b } = builders(tiptapEditor.schema);

/**
 * Returns a text node with the given value.
 *
 * @param {string} val
 * @returns {Node}
 */
const text = (val) => tiptapEditor.state.schema.text(val);

export { b as builders, doc, text };

/**
 * Serializes the given content into markdown with the given options.
 *
 * @param {object} options
 * @param  {(Node | Mark)[]} content
 * @returns {string} Serialized markdown
 */
export const serializeWithOptions = (options, ...content) =>
  new MarkdownSerializer().serialize({ doc: doc(...content) }, options);

/**
 * Serializes the given content into markdown.
 *
 * @param  {(Node | Mark)[]} content
 * @returns {string} Serialized markdown
 */
export const serialize = (...content) =>
  new MarkdownSerializer().serialize({ doc: doc(...content) });

/**
 * Deserializes HTML rendered by the markdown API and serializes the resulting
 * document back to markdown, the way the editor loads and saves a document.
 *
 * @param {string} html
 * @returns {Promise<string>} Serialized markdown
 */
export const roundTrip = async (html) => {
  const deserializer = createMarkdownDeserializer({
    render: () => Promise.resolve({ body: html }),
  });
  const { document } = await deserializer.deserialize({
    schema: tiptapEditor.schema,
    markdown: html,
  });

  return new MarkdownSerializer().serialize({ doc: document });
};

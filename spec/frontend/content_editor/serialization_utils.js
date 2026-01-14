import { builders } from 'prosemirror-test-builder';
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

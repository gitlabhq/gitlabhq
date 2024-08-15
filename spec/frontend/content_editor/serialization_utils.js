import { uniqueId } from 'lodash';
import { builders } from 'prosemirror-test-builder';
import Sourcemap from '~/content_editor/extensions/sourcemap';
import MarkdownSerializer from '~/content_editor/services/markdown_serializer';
import { createTiptapEditor } from './test_utils';
/**
 * @import { Node, Mark } from '@tiptap/pm/model';
 */

jest.mock('~/emoji');

export const tiptapEditor = createTiptapEditor([Sourcemap]);
const { doc, ...b } = builders(tiptapEditor.schema);

/**
 * Returns a text node with the given value.
 *
 * @param {string} val
 * @returns {Node}
 */
const text = (val) => tiptapEditor.state.schema.text(val);

/**
 * Returns a doc node with the given attrs and content.
 *
 * @param {object} attrs
 * @param {(Node | Mark)[]} content
 */
const docWithAttrs = (attrs, ...content) => Object.assign(doc(...content), { attrs });

export { b as builders, doc, text };

/**
 * Serializes the given content into markdown with the given options.
 *
 * @param {{ pristineDoc: Node, referenceDefinitions: string, ...options: object }} param0
 * @param  {(Node | Mark)[]} content
 * @returns {string} Serialized markdown
 */
export const serializeWithOptions = (
  { pristineDoc, referenceDefinitions = '', ...options },
  ...content
) =>
  new MarkdownSerializer().serialize(
    {
      doc: doc(...content),
      pristineDoc: pristineDoc && docWithAttrs({ referenceDefinitions }, pristineDoc),
    },
    options,
  );

/**
 * Serializes the given content into markdown.
 *
 * @param  {(Node | Mark)[]} content
 * @returns {string} Serialized markdown
 */
export const serialize = (...content) =>
  new MarkdownSerializer().serialize({ doc: doc(...content), pristineDoc: doc(...content) });

/**
 * Generates source map attributes containing source markdown, key and tag name.
 *
 * @param {string} sourceMarkdown
 * @param {string} sourceTagName
 * @returns {{ sourceMarkdown: string, sourceMapKey: string, sourceTagName: string }}
 */
export const source = (sourceMarkdown, sourceTagName) => ({
  sourceMarkdown,
  sourceMapKey: uniqueId('key-'),
  sourceTagName,
});

/**
 * Generates source map attributes containing just the tag name.
 *
 * @param {string} sourceTagName
 * @returns {{ sourceTagName: string }}
 */
export const sourceTag = (sourceTagName) => ({ sourceTagName });

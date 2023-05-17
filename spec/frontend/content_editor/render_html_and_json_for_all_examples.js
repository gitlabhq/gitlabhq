import { DOMSerializer } from '@tiptap/pm/model';
import createMarkdownDeserializer from '~/content_editor/services/remark_markdown_deserializer';
import { createTiptapEditor } from 'jest/content_editor/test_utils';

const tiptapEditor = createTiptapEditor();

export const IMPLEMENTATION_ERROR_MSG = 'Error - check implementation';

async function renderMarkdownToHTMLAndJSON(markdown, schema, deserializer) {
  let prosemirrorDocument;
  try {
    const { document } = await deserializer.deserialize({ schema, markdown });
    prosemirrorDocument = document;
  } catch (e) {
    const errorMsg = `${IMPLEMENTATION_ERROR_MSG}:\n${e.message}`;
    return {
      html: errorMsg,
      json: errorMsg,
    };
  }

  const documentFragment = DOMSerializer.fromSchema(schema).serializeFragment(
    prosemirrorDocument.content,
  );
  const htmlString = Array.from(documentFragment.children)
    .map((el) => el.outerHTML)
    .join('\n');

  const json = prosemirrorDocument.toJSON();
  const jsonString = JSON.stringify(json, null, 2);
  return { html: htmlString, json: jsonString };
}

export function renderHtmlAndJsonForAllExamples(markdownExamples) {
  const { schema } = tiptapEditor;
  const deserializer = createMarkdownDeserializer();
  const exampleNames = Object.keys(markdownExamples);

  return exampleNames.reduce(async (promisedExamples, exampleName) => {
    const markdown = markdownExamples[exampleName];
    const htmlAndJson = await renderMarkdownToHTMLAndJSON(markdown, schema, deserializer);
    const examples = await promisedExamples;
    examples[exampleName] = htmlAndJson;
    return examples;
  }, Promise.resolve({}));
}

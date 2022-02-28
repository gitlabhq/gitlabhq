import { DOMParser as ProseMirrorDOMParser } from 'prosemirror-model';

export default ({ render }) => {
  /**
   * Converts a Markdown string into a ProseMirror JSONDocument based
   * on a ProseMirror schema.
   * @param {ProseMirror.Schema} params.schema A ProseMirror schema that defines
   * the types of content supported in the document
   * @param {String} params.content An arbitrary markdown string
   * @returns A ProseMirror JSONDocument
   */
  return {
    deserialize: async ({ schema, content }) => {
      const html = await render(content);

      if (!html) return null;

      const parser = new DOMParser();
      const { body } = parser.parseFromString(html, 'text/html');

      // append original source as a comment that nodes can access
      body.append(document.createComment(content));

      return ProseMirrorDOMParser.fromSchema(schema).parse(body);
    },
  };
};

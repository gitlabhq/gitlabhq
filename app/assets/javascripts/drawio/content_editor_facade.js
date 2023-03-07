import axios from '~/lib/utils/axios_utils';

/**
 * A set of functions to decouple the content_editor component from
 * the draw.io editor.
 * It allows the draw.io editor to obtain a selected drawio_diagram
 * and replace it or insert a new drawio_diagram node without coupling
 * the drawio_editor to the Content Editor implementation details
 * *
 * @param {Object} params Factory function parameters
 * @param {Object} params.tiptapEditor See https://tiptap.dev/api/editor
 * @param {String} params.drawioNodeName Name of the drawio_diagram node in
 * the ProseMirror document
 * @param {String} params.uploadsPath API endpoint to upload files
 * @param {Object} params.assetResolver See
 * app/assets/javascripts/content_editor/services/asset_resolver.js
 *
 * @returns A content_editor_facade object with operations
 * to get a selected diagram, upload a diagram, insert a new one in the
 * Content Editor, and update an existing’s diagram URL.
 */
export const create = ({ tiptapEditor, drawioNodeName, uploadsPath, assetResolver }) => ({
  getDiagram: async () => {
    const { node } = tiptapEditor.state.selection;

    if (!node || node.type.name !== drawioNodeName) {
      return null;
    }

    const { src } = node.attrs;
    const response = await axios.get(src, { responseType: 'text' });
    const diagramSvg = response.data;
    const contentType = response.headers['content-type'];
    const filename = src.split('/').pop();

    return {
      diagramURL: src,
      filename,
      diagramSvg,
      contentType,
    };
  },
  updateDiagram: async ({ uploadResults: { file_path: canonicalSrc } }) => {
    const src = await assetResolver.resolveUrl(canonicalSrc);

    tiptapEditor
      .chain()
      .focus()
      .updateAttributes(drawioNodeName, {
        src,
        canonicalSrc,
      })
      .run();
  },
  insertDiagram: async ({ uploadResults: { file_path: canonicalSrc } }) => {
    const src = await assetResolver.resolveUrl(canonicalSrc);

    tiptapEditor
      .chain()
      .focus()
      .insertContent({
        type: drawioNodeName,
        attrs: {
          src,
          canonicalSrc,
        },
      })
      .run();
  },
  uploadDiagram: async ({ filename, diagramSvg }) => {
    const blob = new Blob([diagramSvg], { type: 'image/svg+xml' });
    const formData = new FormData();

    formData.append('file', blob, filename);

    const response = await axios.post(uploadsPath, formData);

    return response.data;
  },
});

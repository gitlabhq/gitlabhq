import { insertMarkdownText, resolveSelectedImage } from '~/lib/utils/text_markdown';
import axios from '~/lib/utils/axios_utils';

/**
 * A set of functions to decouple the markdown_field component from
 * the draw.io editor.
 * It allows the draw.io editor to obtain a selected drawio_diagram
 * and replace it or insert a new drawio_diagram node without coupling
 * the drawio_editor to the Markdown Field implementation details
 *
 * @param {Object} params Factory function parameters
 * @param {Object} params.textArea Textarea used to edit and display markdown source
 * @param {String} params.markdownPreviewPath API endpoint to render Markdown
 * @param {String} params.uploadsPath API endpoint to upload files
 *
 * @returns A markdown_field_facade object with operations
 * with operations to get a selected diagram, upload a diagram,
 * insert a new one in the Markdown Field, and update
 * an existing’s diagram URL.
 */
export const create = ({ textArea, markdownPreviewPath, uploadsPath }) => ({
  getDiagram: async () => {
    const image = await resolveSelectedImage(textArea, markdownPreviewPath);

    if (!image) {
      return null;
    }

    const { imageURL, imageMarkdown, filename } = image;
    const response = await axios.get(imageURL, { responseType: 'text' });
    const diagramSvg = response.data;
    const contentType = response.headers['content-type'];

    return {
      diagramURL: imageURL,
      diagramMarkdown: imageMarkdown,
      filename,
      diagramSvg,
      contentType,
    };
  },
  updateDiagram: ({ uploadResults, diagramMarkdown }) => {
    textArea.focus();

    // eslint-disable-next-line no-param-reassign
    textArea.value = textArea.value.replace(diagramMarkdown, uploadResults.link.markdown);
    textArea.dispatchEvent(new Event('input'));
  },
  insertDiagram: ({ uploadResults }) => {
    textArea.focus();
    const markdown = textArea.value;
    const selectedMD = markdown.substring(textArea.selectionStart, textArea.selectionEnd);

    // This method dispatches the input event.
    insertMarkdownText({
      textArea,
      text: markdown,
      tag: uploadResults.link.markdown,
      selected: selectedMD,
    });
  },
  uploadDiagram: async ({ filename, diagramSvg }) => {
    const blob = new Blob([diagramSvg], { type: 'image/svg+xml' });
    const formData = new FormData();

    formData.append('file', blob, filename);

    const response = await axios.post(uploadsPath, formData);

    return response.data;
  },
});

import AxiosMockAdapter from 'axios-mock-adapter';
import { create } from '~/drawio/markdown_field_editor_facade';
import * as textMarkdown from '~/lib/utils/text_markdown';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/lib/utils/text_markdown');

describe('drawio/textareaMarkdownEditor', () => {
  let textArea;
  let textareaMarkdownEditor;
  let axiosMock;

  const markdownPreviewPath = '/markdown/preview';
  const imageURL = '/assets/image.png';
  const diagramMarkdown = '![](image.png)';
  const diagramSvg = '<svg></svg>';
  const contentType = 'image/svg+xml';
  const filename = 'image.png';
  const newDiagramMarkdown = '![](newdiagram.svg)';
  const uploadsPath = '/uploads';

  beforeEach(() => {
    textArea = document.createElement('textarea');
    textareaMarkdownEditor = create({ textArea, markdownPreviewPath, uploadsPath });

    document.body.appendChild(textArea);
  });
  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
    textArea.remove();
  });

  describe('getDiagram', () => {
    describe('when there is a selected diagram', () => {
      beforeEach(() => {
        textMarkdown.resolveSelectedImage.mockReturnValueOnce({
          imageURL,
          imageMarkdown: diagramMarkdown,
          filename,
        });
        axiosMock
          .onGet(imageURL)
          .reply(HTTP_STATUS_OK, diagramSvg, { 'content-type': contentType });
      });

      it('returns diagram information', async () => {
        const diagram = await textareaMarkdownEditor.getDiagram();

        expect(textMarkdown.resolveSelectedImage).toHaveBeenCalledWith(
          textArea,
          markdownPreviewPath,
        );

        expect(diagram).toEqual({
          diagramURL: imageURL,
          diagramMarkdown,
          filename,
          diagramSvg,
          contentType,
        });
      });
    });

    describe('when there is not a selected diagram', () => {
      beforeEach(() => {
        textMarkdown.resolveSelectedImage.mockReturnValueOnce(null);
      });

      it('returns null', async () => {
        const diagram = await textareaMarkdownEditor.getDiagram();

        expect(textMarkdown.resolveSelectedImage).toHaveBeenCalledWith(
          textArea,
          markdownPreviewPath,
        );

        expect(diagram).toBe(null);
      });
    });
  });

  describe('updateDiagram', () => {
    beforeEach(() => {
      jest.spyOn(textArea, 'focus');
      jest.spyOn(textArea, 'dispatchEvent');

      textArea.value = `diagram ${diagramMarkdown}`;

      textareaMarkdownEditor.updateDiagram({
        diagramMarkdown,
        uploadResults: { link: { markdown: newDiagramMarkdown } },
      });
    });

    it('focuses the textarea', () => {
      expect(textArea.focus).toHaveBeenCalled();
    });

    it('replaces previous diagram markdown with new diagram markdown', () => {
      expect(textArea.value).toBe(`diagram ${newDiagramMarkdown}`);
    });

    it('dispatches input event in the textarea', () => {
      expect(textArea.dispatchEvent).toHaveBeenCalledWith(new Event('input'));
    });
  });

  describe('insertDiagram', () => {
    it('inserts markdown text and replaces any selected markdown in the textarea', () => {
      textArea.value = `diagram ${diagramMarkdown}`;
      textArea.setSelectionRange(0, 8);

      textareaMarkdownEditor.insertDiagram({
        uploadResults: { link: { markdown: newDiagramMarkdown } },
      });

      expect(textMarkdown.insertMarkdownText).toHaveBeenCalledWith({
        textArea,
        text: textArea.value,
        tag: newDiagramMarkdown,
        selected: textArea.value.substring(0, 8),
      });
    });
  });

  describe('uploadDiagram', () => {
    it('sends a post request to the uploadsPath containing the diagram svg', async () => {
      const link = { markdown: '![](diagram.drawio.svg)' };
      const blob = new Blob([diagramSvg], { type: 'image/svg+xml' });
      const formData = new FormData();

      formData.append('file', blob, filename);

      axiosMock.onPost(uploadsPath, formData).reply(HTTP_STATUS_OK, {
        link,
      });

      const response = await textareaMarkdownEditor.uploadDiagram({ diagramSvg, filename });

      expect(response).toEqual({ link });
    });
  });
});

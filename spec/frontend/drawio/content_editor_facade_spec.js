import AxiosMockAdapter from 'axios-mock-adapter';
import { create } from '~/drawio/content_editor_facade';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import DrawioDiagram from '~/content_editor/extensions/drawio_diagram';
import axios from '~/lib/utils/axios_utils';
import { PROJECT_WIKI_ATTACHMENT_DRAWIO_DIAGRAM_HTML } from '../content_editor/test_constants';
import { createTestEditor } from '../content_editor/test_utils';

describe('drawio/contentEditorFacade', () => {
  let tiptapEditor;
  let axiosMock;
  let contentEditorFacade;
  let assetResolver;
  const imageURL = '/group1/project1/-/wikis/test-file.drawio.svg';
  const diagramSvg = '<svg></svg>';
  const contentType = 'image/svg+xml';
  const filename = 'test-file.drawio.svg';
  const uploadsPath = '/uploads';
  const canonicalSrc = '/new-diagram.drawio.svg';
  const src = `/uploads${canonicalSrc}`;

  beforeEach(() => {
    assetResolver = {
      resolveUrl: jest.fn(),
    };
    tiptapEditor = createTestEditor({ extensions: [DrawioDiagram] });
    contentEditorFacade = create({
      tiptapEditor,
      drawioNodeName: DrawioDiagram.name,
      uploadsPath,
      assetResolver,
    });
  });
  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
    tiptapEditor.destroy();
  });

  describe('getDiagram', () => {
    describe('when there is a selected diagram', () => {
      beforeEach(() => {
        tiptapEditor
          .chain()
          .setContent(PROJECT_WIKI_ATTACHMENT_DRAWIO_DIAGRAM_HTML)
          .setNodeSelection(1)
          .run();
        axiosMock
          .onGet(imageURL)
          .reply(HTTP_STATUS_OK, diagramSvg, { 'content-type': contentType });
      });

      it('returns diagram information', async () => {
        const diagram = await contentEditorFacade.getDiagram();

        expect(diagram).toEqual({
          diagramURL: imageURL,
          filename,
          diagramSvg,
          contentType,
        });
      });
    });

    describe('when there is not a selected diagram', () => {
      beforeEach(() => {
        tiptapEditor.chain().setContent('<p>text</p>').setNodeSelection(1).run();
      });

      it('returns null', async () => {
        const diagram = await contentEditorFacade.getDiagram();

        expect(diagram).toBe(null);
      });
    });
  });

  describe('updateDiagram', () => {
    beforeEach(() => {
      tiptapEditor
        .chain()
        .setContent(PROJECT_WIKI_ATTACHMENT_DRAWIO_DIAGRAM_HTML)
        .setNodeSelection(1)
        .run();

      assetResolver.resolveUrl.mockReturnValueOnce(src);
      contentEditorFacade.updateDiagram({ uploadResults: { file_path: canonicalSrc } });
    });

    it('updates selected diagram diagram node src and canonicalSrc', () => {
      tiptapEditor.commands.setNodeSelection(1);
      expect(tiptapEditor.state.selection.node.attrs).toMatchObject({
        src,
        canonicalSrc,
      });
    });
  });

  describe('insertDiagram', () => {
    beforeEach(() => {
      tiptapEditor.chain().setContent('<p></p>').run();

      assetResolver.resolveUrl.mockReturnValueOnce(src);
      contentEditorFacade.insertDiagram({ uploadResults: { file_path: canonicalSrc } });
    });

    it('inserts a new draw.io diagram in the document', () => {
      tiptapEditor.commands.setNodeSelection(1);
      expect(tiptapEditor.state.selection.node.attrs).toMatchObject({
        src,
        canonicalSrc,
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
        data: {
          link,
        },
      });

      const response = await contentEditorFacade.uploadDiagram({ diagramSvg, filename });

      expect(response).not.toBe(link);
    });
  });
});

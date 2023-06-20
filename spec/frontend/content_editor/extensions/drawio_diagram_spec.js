import DrawioDiagram from '~/content_editor/extensions/drawio_diagram';
import Image from '~/content_editor/extensions/image';
import { create } from '~/drawio/content_editor_facade';
import { launchDrawioEditor } from '~/drawio/drawio_editor';
import { createTestEditor, createDocBuilder } from '../test_utils';
import {
  PROJECT_WIKI_ATTACHMENT_IMAGE_HTML,
  PROJECT_WIKI_ATTACHMENT_DRAWIO_DIAGRAM_HTML,
} from '../test_constants';

jest.mock('~/content_editor/services/asset_resolver');
jest.mock('~/drawio/content_editor_facade');
jest.mock('~/drawio/drawio_editor');

describe('content_editor/extensions/drawio_diagram', () => {
  let tiptapEditor;
  let doc;
  let paragraph;
  let image;
  let drawioDiagram;
  let assetResolver;

  const uploadsPath = '/uploads';

  beforeEach(() => {
    assetResolver = new (class {})();

    tiptapEditor = createTestEditor({
      extensions: [Image, DrawioDiagram.configure({ uploadsPath, assetResolver })],
    });
    const { builders } = createDocBuilder({
      tiptapEditor,
      names: {
        image: { nodeType: Image.name },
        drawioDiagram: { nodeType: DrawioDiagram.name },
      },
    });

    doc = builders.doc;
    paragraph = builders.paragraph;
    image = builders.image;
    drawioDiagram = builders.drawioDiagram;
  });

  describe('parsing', () => {
    it('distinguishes a drawio diagram from an image', () => {
      const expectedDocWithDiagram = doc(
        paragraph(
          drawioDiagram({
            alt: 'test-file',
            canonicalSrc: 'test-file.drawio.svg',
            src: '/group1/project1/-/wikis/test-file.drawio.svg',
          }),
        ),
      );
      const expectedDocWithImage = doc(
        paragraph(
          image({
            alt: 'test-file',
            canonicalSrc: 'test-file.png',
            src: '/group1/project1/-/wikis/test-file.png',
          }),
        ),
      );
      tiptapEditor.commands.setContent(PROJECT_WIKI_ATTACHMENT_DRAWIO_DIAGRAM_HTML);

      expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDocWithDiagram.toJSON());

      tiptapEditor.commands.setContent(PROJECT_WIKI_ATTACHMENT_IMAGE_HTML);

      expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDocWithImage.toJSON());
    });
  });

  describe('createOrEditDiagram command', () => {
    let editorFacade;

    beforeEach(() => {
      editorFacade = {};
      tiptapEditor.commands.createOrEditDiagram();

      create.mockReturnValueOnce(editorFacade);
    });

    it('creates a new instance of the content_editor_facade', () => {
      expect(create).toHaveBeenCalledWith({
        tiptapEditor,
        drawioNodeName: DrawioDiagram.name,
        uploadsPath,
        assetResolver,
      });
    });

    it('calls launchDrawioEditor and provides content_editor_facade', () => {
      expect(launchDrawioEditor).toHaveBeenCalledWith({ editorFacade });
    });
  });
});

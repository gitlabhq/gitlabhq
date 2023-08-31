import { launchDrawioEditor } from '~/drawio/drawio_editor';
import {
  DRAWIO_FRAME_ID,
  DIAGRAM_BACKGROUND_COLOR,
  DRAWIO_IFRAME_TIMEOUT,
  DIAGRAM_MAX_SIZE,
} from '~/drawio/constants';
import { base64EncodeUnicode } from '~/lib/utils/text_utility';
import { createAlert, VARIANT_SUCCESS } from '~/alert';

const DRAWIO_EDITOR_URL =
  'https://embed.diagrams.net/?ui=sketch&noSaveBtn=1&saveAndExit=1&keepmodified=1&spin=1&embed=1&libraries=1&configure=1&proto=json&toSvg=1';
const DRAWIO_EDITOR_ORIGIN = new URL(DRAWIO_EDITOR_URL).origin;

jest.mock('~/alert');

jest.useFakeTimers();

describe('drawio/drawio_editor', () => {
  let editorFacade;
  let drawioIFrameReceivedMessages;
  const diagramURL = `${window.location.origin}/uploads/diagram.drawio.svg`;
  const testSvg = '<svg>😀</svg>';
  const testEncodedSvg = `data:image/svg+xml;base64,${base64EncodeUnicode(testSvg)}`;
  const filename = 'diagram.drawio.svg';

  const findDrawioIframe = () => document.getElementById(DRAWIO_FRAME_ID);
  const waitForDrawioIFrameMessage = ({ messageNumber = 1 } = {}) =>
    new Promise((resolve) => {
      let messageCounter = 0;
      const iframe = findDrawioIframe();

      iframe?.contentWindow.addEventListener('message', (event) => {
        drawioIFrameReceivedMessages.push(event);

        messageCounter += 1;

        if (messageCounter === messageNumber) {
          resolve();
        }
      });
    });
  const expectDrawioIframeMessage = ({ expectation, messageNumber = 1 }) => {
    expect(drawioIFrameReceivedMessages).toHaveLength(messageNumber);
    expect(JSON.parse(drawioIFrameReceivedMessages[messageNumber - 1].data)).toEqual(expectation);
  };
  const postMessageToParentWindow = (data) => {
    const event = new Event('message');

    Object.setPrototypeOf(event, {
      source: findDrawioIframe().contentWindow,
      data: JSON.stringify(data),
    });

    window.dispatchEvent(event);
  };

  beforeEach(() => {
    editorFacade = {
      getDiagram: jest.fn(),
      uploadDiagram: jest.fn(),
      insertDiagram: jest.fn(),
      updateDiagram: jest.fn(),
    };
    drawioIFrameReceivedMessages = [];
    gon.diagramsnet_url = DRAWIO_EDITOR_ORIGIN;
  });

  afterEach(() => {
    findDrawioIframe()?.remove();
  });

  describe('initializing', () => {
    beforeEach(() => {
      launchDrawioEditor({ editorFacade });
    });

    it('creates the drawio editor iframe and attaches it to the body', () => {
      expect(findDrawioIframe().getAttribute('src')).toBe(DRAWIO_EDITOR_URL);
    });

    it('sets drawio-editor classname to the iframe', () => {
      expect(findDrawioIframe().classList).toContain('drawio-editor');
    });
  });

  describe(`when parent window does not receive configure event after ${DRAWIO_IFRAME_TIMEOUT} ms`, () => {
    beforeEach(() => {
      launchDrawioEditor({ editorFacade });
    });

    it('disposes draw.io iframe', () => {
      expect(findDrawioIframe()).not.toBe(null);
      jest.runAllTimers();
      expect(findDrawioIframe()).toBe(null);
    });

    it('displays an alert indicating that the draw.io editor could not be loaded', () => {
      jest.runAllTimers();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'The diagrams.net editor could not be loaded.',
      });
    });
  });

  describe('when parent window receives configure event', () => {
    beforeEach(async () => {
      launchDrawioEditor({ editorFacade });
      postMessageToParentWindow({ event: 'configure' });

      await waitForDrawioIFrameMessage();
    });

    it('sends configure action to the draw.io iframe', () => {
      expectDrawioIframeMessage({
        expectation: {
          action: 'configure',
          config: {
            darkColor: '#202020',
            settingsName: 'gitlab',
          },
          colorSchemeMeta: false,
        },
      });
    });

    it('does not remove the iframe after the load error timeouts run', () => {
      jest.runAllTimers();

      expect(findDrawioIframe()).not.toBe(null);
    });
  });

  describe('when parent window receives init event', () => {
    describe('when there isn’t a diagram selected', () => {
      beforeEach(() => {
        editorFacade.getDiagram.mockResolvedValueOnce(null);

        launchDrawioEditor({ editorFacade });

        postMessageToParentWindow({ event: 'init' });
      });

      it('sends load action to the draw.io iframe with empty svg and title', async () => {
        await waitForDrawioIFrameMessage();

        expectDrawioIframeMessage({
          expectation: {
            action: 'load',
            xml: null,
            border: 8,
            background: DIAGRAM_BACKGROUND_COLOR,
            dark: false,
            title: null,
          },
        });
      });
    });

    describe('when there is a diagram selected', () => {
      const diagramSvg = '<svg></svg>';

      beforeEach(() => {
        editorFacade.getDiagram.mockResolvedValueOnce({
          diagramURL,
          diagramSvg,
          filename,
          contentType: 'image/svg+xml',
        });

        launchDrawioEditor({ editorFacade });
        postMessageToParentWindow({ event: 'init' });
      });

      it('sends load action to the draw.io iframe with the selected diagram svg and filename', async () => {
        await waitForDrawioIFrameMessage();

        // Step 5: The draw.io editor will send the downloaded diagram to the iframe
        expectDrawioIframeMessage({
          expectation: {
            action: 'load',
            xml: diagramSvg,
            border: 8,
            background: DIAGRAM_BACKGROUND_COLOR,
            dark: false,
            title: filename,
          },
        });
      });

      it('sets the drawio iframe as visible and resets cursor', async () => {
        await waitForDrawioIFrameMessage();

        expect(findDrawioIframe().style.visibility).toBe('visible');
        expect(findDrawioIframe().style.cursor).toBe('');
      });

      it('scrolls window to the top', async () => {
        await waitForDrawioIFrameMessage();

        expect(window.scrollX).toBe(0);
      });
    });

    describe.each`
      description | errorMessage | diagram
      ${'when there is an image selected that is not an svg file'} | ${'The selected image is not a valid SVG diagram'} | ${{
  diagramURL,
  contentType: 'image/png',
  filename: 'image.png',
}}
      ${'when the selected image is not an asset upload'} | ${'The selected image is not an asset uploaded in the application'} | ${{
  diagramSvg: '<svg></svg>',
  filename,
  contentType: 'image/svg+xml',
  diagramURL: 'https://example.com/image.drawio.svg',
}}
      ${'when the selected image is too large'} | ${'The selected image is too large.'} | ${{
  diagramSvg: 'x'.repeat(DIAGRAM_MAX_SIZE + 1),
  filename,
  contentType: 'image/svg+xml',
  diagramURL,
}}
    `('$description', ({ errorMessage, diagram }) => {
      beforeEach(() => {
        editorFacade.getDiagram.mockResolvedValueOnce(diagram);

        launchDrawioEditor({ editorFacade });

        postMessageToParentWindow({ event: 'init' });
      });

      it('displays an error alert indicating that the image is not a diagram', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: errorMessage,
          error: expect.any(Error),
        });
      });

      it('disposes the draw.io diagram iframe', () => {
        expect(findDrawioIframe()).toBe(null);
      });
    });

    describe('when loading a diagram fails', () => {
      beforeEach(() => {
        editorFacade.getDiagram.mockRejectedValueOnce(new Error());

        launchDrawioEditor({ editorFacade });

        postMessageToParentWindow({ event: 'init' });
      });

      it('displays an error alert indicating the failure', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Cannot load the diagram into the diagrams.net editor',
          error: expect.any(Error),
        });
      });

      it('disposes the draw.io diagram iframe', () => {
        expect(findDrawioIframe()).toBe(null);
      });
    });
  });

  describe('when parent window receives prompt event', () => {
    describe('when the filename is empty', () => {
      beforeEach(() => {
        launchDrawioEditor({ editorFacade });

        postMessageToParentWindow({ event: 'prompt', value: '' });
      });

      it('sends prompt action to the draw.io iframe requesting a filename', async () => {
        await waitForDrawioIFrameMessage({ messageNumber: 1 });

        expectDrawioIframeMessage({
          expectation: {
            action: 'prompt',
            titleKey: 'filename',
            okKey: 'save',
            defaultValue: 'diagram.drawio.svg',
          },
          messageNumber: 1,
        });
      });

      it('sends dialog action to the draw.io iframe indicating that the filename cannot be empty', async () => {
        await waitForDrawioIFrameMessage({ messageNumber: 2 });

        expectDrawioIframeMessage({
          expectation: {
            action: 'dialog',
            titleKey: 'error',
            messageKey: 'filenameShort',
            buttonKey: 'ok',
          },
          messageNumber: 2,
        });
      });
    });

    describe('when the event data is not empty', () => {
      beforeEach(async () => {
        launchDrawioEditor({ editorFacade });
        postMessageToParentWindow({ event: 'prompt', value: 'diagram.drawio.svg' });

        await waitForDrawioIFrameMessage();
      });

      it('starts the saving file process', () => {
        expectDrawioIframeMessage({
          expectation: {
            action: 'spinner',
            show: true,
            messageKey: 'saving',
          },
        });
      });
    });
  });

  describe('when parent receives export event', () => {
    beforeEach(() => {
      editorFacade.uploadDiagram.mockResolvedValueOnce({});
    });

    it('reloads diagram in the draw.io editor', async () => {
      launchDrawioEditor({ editorFacade });
      postMessageToParentWindow({ event: 'export', data: testEncodedSvg });

      await waitForDrawioIFrameMessage();

      expectDrawioIframeMessage({
        expectation: expect.objectContaining({
          action: 'load',
          xml: expect.stringContaining(testSvg),
        }),
      });
    });

    it('marks the diagram as modified in the draw.io editor', async () => {
      launchDrawioEditor({ editorFacade });
      postMessageToParentWindow({ event: 'export', data: testEncodedSvg });

      await waitForDrawioIFrameMessage({ messageNumber: 2 });

      expectDrawioIframeMessage({
        expectation: expect.objectContaining({
          action: 'status',
          modified: true,
        }),
        messageNumber: 2,
      });
    });

    describe('when the diagram filename is set', () => {
      const TEST_FILENAME = 'diagram.drawio.svg';

      beforeEach(() => {
        launchDrawioEditor({
          editorFacade,
          filename: TEST_FILENAME,
          drawioUrl: DRAWIO_EDITOR_ORIGIN,
        });
      });

      it('displays loading spinner in the draw.io editor', async () => {
        postMessageToParentWindow({ event: 'export', data: testEncodedSvg });

        await waitForDrawioIFrameMessage({ messageNumber: 3 });

        expectDrawioIframeMessage({
          expectation: {
            action: 'spinner',
            show: true,
            messageKey: 'saving',
          },
          messageNumber: 3,
        });
      });

      it('uploads exported diagram', async () => {
        postMessageToParentWindow({ event: 'export', data: testEncodedSvg });

        await waitForDrawioIFrameMessage({ messageNumber: 3 });

        expect(editorFacade.uploadDiagram).toHaveBeenCalledWith({
          filename: TEST_FILENAME,
          diagramSvg: expect.stringContaining(testSvg),
        });
      });

      describe('when uploading the exported diagram succeeds', () => {
        it('displays an alert indicating that the diagram was uploaded successfully', async () => {
          postMessageToParentWindow({ event: 'export', data: testEncodedSvg });

          await waitForDrawioIFrameMessage({ messageNumber: 3 });

          expect(createAlert).toHaveBeenCalledWith({
            message: expect.any(String),
            variant: VARIANT_SUCCESS,
            fadeTransition: true,
          });
        });

        it('disposes iframe', () => {
          jest.runAllTimers();

          expect(findDrawioIframe()).toBe(null);
        });
      });

      describe('when uploading the exported diagram fails', () => {
        const uploadError = new Error();

        beforeEach(() => {
          editorFacade.uploadDiagram.mockReset();
          editorFacade.uploadDiagram.mockRejectedValue(uploadError);

          postMessageToParentWindow({ event: 'export', data: testEncodedSvg });
        });

        it('hides loading indicator in the draw.io editor', async () => {
          await waitForDrawioIFrameMessage({ messageNumber: 4 });

          expectDrawioIframeMessage({
            expectation: {
              action: 'spinner',
              show: false,
            },
            messageNumber: 4,
          });
        });

        it('displays an error dialog in the draw.io editor', async () => {
          await waitForDrawioIFrameMessage({ messageNumber: 5 });

          expectDrawioIframeMessage({
            expectation: {
              action: 'dialog',
              titleKey: 'error',
              modified: true,
              buttonKey: 'close',
              messageKey: 'errorSavingFile',
            },
            messageNumber: 5,
          });
        });
      });
    });

    describe('when diagram filename is not set', () => {
      it('sends prompt action to the draw.io iframe', async () => {
        launchDrawioEditor({ editorFacade });
        postMessageToParentWindow({ event: 'export', data: testEncodedSvg });

        await waitForDrawioIFrameMessage({ messageNumber: 3 });

        expect(drawioIFrameReceivedMessages[2].data).toEqual(
          JSON.stringify({
            action: 'prompt',
            titleKey: 'filename',
            okKey: 'save',
            defaultValue: 'diagram.drawio.svg',
          }),
        );
      });
    });
  });

  describe('when parent window receives exit event', () => {
    beforeEach(() => {
      launchDrawioEditor({ editorFacade });
    });

    it('disposes the the draw.io iframe', () => {
      expect(findDrawioIframe()).not.toBe(null);

      postMessageToParentWindow({ event: 'exit' });

      expect(findDrawioIframe()).toBe(null);
    });
  });
});

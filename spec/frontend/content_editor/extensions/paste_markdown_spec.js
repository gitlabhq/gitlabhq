import PasteMarkdown from '~/content_editor/extensions/paste_markdown';
import Bold from '~/content_editor/extensions/bold';
import { VARIANT_DANGER } from '~/flash';
import eventHubFactory from '~/helpers/event_hub_factory';
import {
  ALERT_EVENT,
  LOADING_CONTENT_EVENT,
  LOADING_SUCCESS_EVENT,
  LOADING_ERROR_EVENT,
} from '~/content_editor/constants';
import waitForPromises from 'helpers/wait_for_promises';
import { createTestEditor, createDocBuilder, waitUntilNextDocTransaction } from '../test_utils';

describe('content_editor/extensions/paste_markdown', () => {
  let tiptapEditor;
  let doc;
  let p;
  let bold;
  let renderMarkdown;
  let eventHub;
  const defaultData = { 'text/plain': '**bold text**' };

  beforeEach(() => {
    renderMarkdown = jest.fn();
    eventHub = eventHubFactory();

    jest.spyOn(eventHub, '$emit');

    tiptapEditor = createTestEditor({
      extensions: [PasteMarkdown.configure({ renderMarkdown, eventHub }), Bold],
    });

    ({
      builders: { doc, p, bold },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        Bold: { markType: Bold.name },
      },
    }));
  });

  const buildClipboardEvent = ({ data = {}, types = ['text/plain'] } = {}) => {
    return Object.assign(new Event('paste'), {
      clipboardData: { types, getData: jest.fn((type) => data[type] || defaultData[type]) },
    });
  };

  const triggerPasteEventHandler = (event) => {
    let handled = false;

    tiptapEditor.view.someProp('handlePaste', (eventHandler) => {
      handled = eventHandler(tiptapEditor.view, event);
    });

    return handled;
  };

  const triggerPasteEventHandlerAndWaitForTransaction = (event) => {
    return waitUntilNextDocTransaction({
      tiptapEditor,
      action: () => {
        tiptapEditor.view.someProp('handlePaste', (eventHandler) => {
          return eventHandler(tiptapEditor.view, event);
        });
      },
    });
  };

  it.each`
    types                                                | data                                                  | handled  | desc
    ${['text/plain']}                                    | ${{}}                                                 | ${true}  | ${'handles plain text'}
    ${['text/plain', 'text/html']}                       | ${{}}                                                 | ${false} | ${'doesn’t handle html format'}
    ${['text/plain', 'text/html', 'vscode-editor-data']} | ${{ 'vscode-editor-data': '{ "mode": "markdown" }' }} | ${true}  | ${'handles vscode markdown'}
    ${['text/plain', 'text/html', 'vscode-editor-data']} | ${{ 'vscode-editor-data': '{ "mode": "ruby" }' }}     | ${false} | ${'doesn’t vscode code snippet'}
  `('$desc', ({ types, handled, data }) => {
    expect(triggerPasteEventHandler(buildClipboardEvent({ types, data }))).toBe(handled);
  });

  describe('when pasting raw markdown source', () => {
    describe('when rendering markdown succeeds', () => {
      beforeEach(() => {
        renderMarkdown.mockResolvedValueOnce('<strong>bold text</strong>');
      });

      it('transforms pasted text into a prosemirror node', async () => {
        const expectedDoc = doc(p(bold('bold text')));

        await triggerPasteEventHandlerAndWaitForTransaction(buildClipboardEvent());

        expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
      });

      it(`triggers ${LOADING_SUCCESS_EVENT}`, async () => {
        await triggerPasteEventHandlerAndWaitForTransaction(buildClipboardEvent());

        expect(eventHub.$emit).toHaveBeenCalledWith(LOADING_CONTENT_EVENT);
        expect(eventHub.$emit).toHaveBeenCalledWith(LOADING_SUCCESS_EVENT);
      });
    });

    describe('when rendering markdown fails', () => {
      beforeEach(() => {
        renderMarkdown.mockRejectedValueOnce();
      });

      it(`triggers ${LOADING_ERROR_EVENT} event`, async () => {
        triggerPasteEventHandler(buildClipboardEvent());

        await waitForPromises();

        expect(eventHub.$emit).toHaveBeenCalledWith(LOADING_ERROR_EVENT);
      });

      it(`triggers ${ALERT_EVENT} event`, async () => {
        triggerPasteEventHandler(buildClipboardEvent());

        await waitForPromises();

        expect(eventHub.$emit).toHaveBeenCalledWith(ALERT_EVENT, {
          message: expect.any(String),
          variant: VARIANT_DANGER,
        });
      });
    });
  });
});

import initCopyToClipboard, {
  CLIPBOARD_SUCCESS_EVENT,
  CLIPBOARD_ERROR_EVENT,
  I18N_ERROR_MESSAGE,
} from '~/behaviors/copy_to_clipboard';
import { show, hide, fixTitle, once } from '~/tooltips';

let onceCallback = () => {};
jest.mock('~/tooltips', () => ({
  show: jest.fn(),
  hide: jest.fn(),
  fixTitle: jest.fn(),
  once: jest.fn((event, callback) => {
    onceCallback = callback;
  }),
}));

describe('initCopyToClipboard', () => {
  let clearSelection;
  let focusSpy;
  let dispatchEventSpy;
  let button;
  let clipboardInstance;

  afterEach(() => {
    document.body.innerHTML = '';
    clipboardInstance = null;
  });

  const title = 'Copy this value';
  const defaultButtonAttributes = {
    'data-clipboard-text': 'foo bar',
    title,
    'data-original-title': title,
  };
  const createButton = (attributes = {}) => {
    const combinedAttributes = { ...defaultButtonAttributes, ...attributes };
    button = document.createElement('button');
    Object.keys(combinedAttributes).forEach((attributeName) => {
      button.setAttribute(attributeName, combinedAttributes[attributeName]);
    });
    document.body.appendChild(button);
  };

  const init = () => {
    clipboardInstance = initCopyToClipboard();
  };

  const setupSpies = () => {
    clearSelection = jest.fn();
    focusSpy = jest.spyOn(button, 'focus');
    dispatchEventSpy = jest.spyOn(button, 'dispatchEvent');
  };

  const emitSuccessEvent = () => {
    clipboardInstance.emit('success', {
      action: 'copy',
      text: 'foo bar',
      trigger: button,
      clearSelection,
    });
  };

  const emitErrorEvent = () => {
    clipboardInstance.emit('error', {
      action: 'copy',
      text: 'foo bar',
      trigger: button,
      clearSelection,
    });
  };

  const itHandlesTooltip = (expectedTooltip) => {
    it('handles tooltip', () => {
      expect(button.getAttribute('title')).toBe(expectedTooltip);
      expect(button.getAttribute('aria-label')).toBe(expectedTooltip);
      expect(fixTitle).toHaveBeenCalledWith(button);
      expect(show).toHaveBeenCalledWith(button);
      expect(once).toHaveBeenCalledWith('hidden', expect.any(Function));

      expect(hide).not.toHaveBeenCalled();
      jest.runAllTimers();
      expect(hide).toHaveBeenCalled();

      onceCallback({ target: button });
      expect(button.getAttribute('title')).toBe(title);
      expect(button.getAttribute('aria-label')).toBe(title);
      expect(fixTitle).toHaveBeenCalledWith(button);
    });
  };

  describe('when value is successfully copied', () => {
    it(`calls clearSelection, focuses the button, and dispatches ${CLIPBOARD_SUCCESS_EVENT} event`, () => {
      createButton();
      init();
      setupSpies();
      emitSuccessEvent();

      expect(clearSelection).toHaveBeenCalled();
      expect(focusSpy).toHaveBeenCalled();
      expect(dispatchEventSpy).toHaveBeenCalledWith(new Event(CLIPBOARD_SUCCESS_EVENT));
    });

    describe('when `data-clipboard-handle-tooltip` is set to `false`', () => {
      beforeEach(() => {
        createButton({
          'data-clipboard-handle-tooltip': 'false',
        });
        init();
        emitSuccessEvent();
      });

      it('does not handle success tooltip', () => {
        expect(show).not.toHaveBeenCalled();
      });
    });

    describe('when `data-clipboard-handle-tooltip` is set to `true`', () => {
      beforeEach(() => {
        createButton({
          'data-clipboard-handle-tooltip': 'true',
        });
        init();
        emitSuccessEvent();
      });

      itHandlesTooltip('Copied');
    });

    describe('when `data-clipboard-handle-tooltip` is not set', () => {
      beforeEach(() => {
        createButton();
        init();
        emitSuccessEvent();
      });

      itHandlesTooltip('Copied');
    });
  });

  describe('when there is an error copying the value', () => {
    it(`dispatches ${CLIPBOARD_ERROR_EVENT} event`, () => {
      createButton();
      init();
      setupSpies();
      emitErrorEvent();

      expect(dispatchEventSpy).toHaveBeenCalledWith(new Event(CLIPBOARD_ERROR_EVENT));
    });

    describe('when `data-clipboard-handle-tooltip` is set to `false`', () => {
      beforeEach(() => {
        createButton({
          'data-clipboard-handle-tooltip': 'false',
        });
        init();
        emitErrorEvent();
      });

      it('does not handle error tooltip', () => {
        expect(show).not.toHaveBeenCalled();
      });
    });

    describe('when `data-clipboard-handle-tooltip` is set to `true`', () => {
      beforeEach(() => {
        createButton({
          'data-clipboard-handle-tooltip': 'true',
        });
        init();
        emitErrorEvent();
      });

      itHandlesTooltip(I18N_ERROR_MESSAGE);
    });

    describe('when `data-clipboard-handle-tooltip` is not set', () => {
      beforeEach(() => {
        createButton();
        init();
        emitErrorEvent();
      });

      itHandlesTooltip(I18N_ERROR_MESSAGE);
    });
  });
});

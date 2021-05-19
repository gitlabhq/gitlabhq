import { Range } from 'monaco-editor';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import {
  ERROR_INSTANCE_REQUIRED_FOR_EXTENSION,
  EDITOR_TYPE_CODE,
  EDITOR_TYPE_DIFF,
} from '~/editor/constants';
import { EditorLiteExtension } from '~/editor/extensions/editor_lite_extension_base';

jest.mock('~/helpers/startup_css_helper', () => {
  return {
    waitForCSSLoaded: jest.fn().mockImplementation((cb) => {
      // We have to artificially put the callback's execution
      // to the end of the current call stack to be able to
      // test that the callback is called after waitForCSSLoaded.
      // setTimeout with 0 delay does exactly that.
      // Otherwise we might end up with false positive results
      setTimeout(() => {
        cb.apply();
      }, 0);
    }),
  };
});

describe('The basis for an Editor Lite extension', () => {
  const defaultLine = 3;
  let ext;
  let event;

  const defaultOptions = { foo: 'bar' };
  const findLine = (num) => {
    return document.querySelector(`.line-numbers:nth-child(${num})`);
  };
  const generateLines = () => {
    let res = '';
    for (let line = 1, lines = 5; line <= lines; line += 1) {
      res += `<div class="line-numbers">${line}</div>`;
    }
    return res;
  };
  const generateEventMock = ({ line = defaultLine, el = null } = {}) => {
    return {
      target: {
        element: el || findLine(line),
        position: {
          lineNumber: line,
        },
      },
    };
  };

  beforeEach(() => {
    setFixtures(generateLines());
    event = generateEventMock();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('constructor', () => {
    it('resets the layout in waitForCSSLoaded callback', async () => {
      const instance = {
        layout: jest.fn(),
      };
      ext = new EditorLiteExtension({ instance });
      expect(instance.layout).not.toHaveBeenCalled();

      // We're waiting for the waitForCSSLoaded mock to kick in
      await jest.runOnlyPendingTimers();

      expect(instance.layout).toHaveBeenCalled();
    });

    it.each`
      description                                                     | instance     | options
      ${'accepts configuration options and instance'}                 | ${{}}        | ${defaultOptions}
      ${'leaves instance intact if no options are passed'}            | ${{}}        | ${undefined}
      ${'does not fail if both instance and the options are omitted'} | ${undefined} | ${undefined}
      ${'throws if only options are passed'}                          | ${undefined} | ${defaultOptions}
    `('$description', ({ instance, options } = {}) => {
      EditorLiteExtension.deferRerender = jest.fn();
      const originalInstance = { ...instance };

      if (instance) {
        if (options) {
          Object.entries(options).forEach((prop) => {
            expect(instance[prop]).toBeUndefined();
          });
          // Both instance and options are passed
          ext = new EditorLiteExtension({ instance, ...options });
          Object.entries(options).forEach(([prop, value]) => {
            expect(ext[prop]).toBeUndefined();
            expect(instance[prop]).toBe(value);
          });
        } else {
          ext = new EditorLiteExtension({ instance });
          expect(instance).toEqual(originalInstance);
        }
      } else if (options) {
        // Options are passed without instance
        expect(() => {
          ext = new EditorLiteExtension({ ...options });
        }).toThrow(ERROR_INSTANCE_REQUIRED_FOR_EXTENSION);
      } else {
        // Neither options nor instance are passed
        expect(() => {
          ext = new EditorLiteExtension();
        }).not.toThrow();
      }
    });

    it('initializes the line highlighting', () => {
      EditorLiteExtension.deferRerender = jest.fn();
      const spy = jest.spyOn(EditorLiteExtension, 'highlightLines');
      ext = new EditorLiteExtension({ instance: {} });
      expect(spy).toHaveBeenCalled();
    });

    it('sets up the line linking for code instance', () => {
      EditorLiteExtension.deferRerender = jest.fn();
      const spy = jest.spyOn(EditorLiteExtension, 'setupLineLinking');
      const instance = {
        getEditorType: jest.fn().mockReturnValue(EDITOR_TYPE_CODE),
        onMouseMove: jest.fn(),
        onMouseDown: jest.fn(),
      };
      ext = new EditorLiteExtension({ instance });
      expect(spy).toHaveBeenCalledWith(instance);
    });

    it('does not set up the line linking for diff instance', () => {
      EditorLiteExtension.deferRerender = jest.fn();
      const spy = jest.spyOn(EditorLiteExtension, 'setupLineLinking');
      const instance = {
        getEditorType: jest.fn().mockReturnValue(EDITOR_TYPE_DIFF),
      };
      ext = new EditorLiteExtension({ instance });
      expect(spy).not.toHaveBeenCalled();
    });
  });

  describe('highlightLines', () => {
    const revealSpy = jest.fn();
    const decorationsSpy = jest.fn();
    const instance = {
      revealLineInCenter: revealSpy,
      deltaDecorations: decorationsSpy,
    };
    const defaultDecorationOptions = { isWholeLine: true, className: 'active-line-text' };

    useFakeRequestAnimationFrame();

    beforeEach(() => {
      delete window.location;
      window.location = new URL(`https://localhost`);
    });

    afterEach(() => {
      window.location.hash = '';
    });

    it.each`
      desc                                               | hash         | shouldReveal | expectedRange
      ${'properly decorates a single line'}              | ${'#L10'}    | ${true}      | ${[10, 1, 10, 1]}
      ${'properly decorates multiple lines'}             | ${'#L7-42'}  | ${true}      | ${[7, 1, 42, 1]}
      ${'correctly highlights if lines are reversed'}    | ${'#L42-7'}  | ${true}      | ${[7, 1, 42, 1]}
      ${'highlights one line if start/end are the same'} | ${'#L7-7'}   | ${true}      | ${[7, 1, 7, 1]}
      ${'does not highlight if there is no hash'}        | ${''}        | ${false}     | ${null}
      ${'does not highlight if the hash is undefined'}   | ${undefined} | ${false}     | ${null}
      ${'does not highlight if hash is incomplete 1'}    | ${'#L'}      | ${false}     | ${null}
      ${'does not highlight if hash is incomplete 2'}    | ${'#L-'}     | ${false}     | ${null}
    `('$desc', ({ hash, shouldReveal, expectedRange } = {}) => {
      window.location.hash = hash;
      EditorLiteExtension.highlightLines(instance);
      if (!shouldReveal) {
        expect(revealSpy).not.toHaveBeenCalled();
        expect(decorationsSpy).not.toHaveBeenCalled();
      } else {
        expect(revealSpy).toHaveBeenCalledWith(expectedRange[0]);
        expect(decorationsSpy).toHaveBeenCalledWith(
          [],
          [
            {
              range: new Range(...expectedRange),
              options: defaultDecorationOptions,
            },
          ],
        );
      }
    });

    it('stores the line  decorations on the instance', () => {
      decorationsSpy.mockReturnValue('foo');
      window.location.hash = '#L10';
      expect(instance.lineDecorations).toBeUndefined();
      EditorLiteExtension.highlightLines(instance);
      expect(instance.lineDecorations).toBe('foo');
    });
  });

  describe('setupLineLinking', () => {
    const instance = {
      onMouseMove: jest.fn(),
      onMouseDown: jest.fn(),
      deltaDecorations: jest.fn(),
      lineDecorations: 'foo',
    };

    beforeEach(() => {
      EditorLiteExtension.onMouseMoveHandler(event); // generate the anchor
    });

    it.each`
      desc             | spy
      ${'onMouseMove'} | ${instance.onMouseMove}
      ${'onMouseDown'} | ${instance.onMouseDown}
    `('sets up the $desc listener', ({ spy } = {}) => {
      EditorLiteExtension.setupLineLinking(instance);
      expect(spy).toHaveBeenCalled();
    });

    it.each`
      desc                                                                                | eventTrigger      | shouldRemove
      ${'does not remove the line decorations if the event is triggered on a wrong node'} | ${null}           | ${false}
      ${'removes existing line decorations when clicking a line number'}                  | ${'.link-anchor'} | ${true}
    `('$desc', ({ eventTrigger, shouldRemove } = {}) => {
      event = generateEventMock({ el: eventTrigger ? document.querySelector(eventTrigger) : null });
      instance.onMouseDown.mockImplementation((fn) => {
        fn(event);
      });

      EditorLiteExtension.setupLineLinking(instance);
      if (shouldRemove) {
        expect(instance.deltaDecorations).toHaveBeenCalledWith(instance.lineDecorations, []);
      } else {
        expect(instance.deltaDecorations).not.toHaveBeenCalled();
      }
    });
  });

  describe('onMouseMoveHandler', () => {
    it('stops propagation for contextmenu event on the generated anchor', () => {
      EditorLiteExtension.onMouseMoveHandler(event);
      const anchor = findLine(defaultLine).querySelector('a');
      const contextMenuEvent = new Event('contextmenu');

      jest.spyOn(contextMenuEvent, 'stopPropagation');
      anchor.dispatchEvent(contextMenuEvent);

      expect(contextMenuEvent.stopPropagation).toHaveBeenCalled();
    });

    it('creates an anchor if it does not exist yet', () => {
      expect(findLine(defaultLine).querySelector('a')).toBe(null);
      EditorLiteExtension.onMouseMoveHandler(event);
      expect(findLine(defaultLine).querySelector('a')).not.toBe(null);
    });

    it('does not create a new anchor if it exists', () => {
      EditorLiteExtension.onMouseMoveHandler(event);
      expect(findLine(defaultLine).querySelector('a')).not.toBe(null);

      EditorLiteExtension.createAnchor = jest.fn();
      EditorLiteExtension.onMouseMoveHandler(event);
      expect(EditorLiteExtension.createAnchor).not.toHaveBeenCalled();
      expect(findLine(defaultLine).querySelectorAll('a')).toHaveLength(1);
    });

    it('does not create a link if the event is triggered on a wrong node', () => {
      setFixtures('<div class="wrong-class">3</div>');
      EditorLiteExtension.createAnchor = jest.fn();
      const wrongEvent = generateEventMock({ el: document.querySelector('.wrong-class') });

      EditorLiteExtension.onMouseMoveHandler(wrongEvent);
      expect(EditorLiteExtension.createAnchor).not.toHaveBeenCalled();
    });
  });
});

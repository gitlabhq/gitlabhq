import $ from 'jquery';
import { flatten } from 'lodash';
import htmlSnippetsShow from 'test_fixtures/snippets/show.html';
import { Mousetrap } from '~/lib/mousetrap';
import { waitForElement } from '~/lib/utils/dom_utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import Shortcuts, { LOCAL_MOUSETRAP_DATA_KEY } from '~/behaviors/shortcuts/shortcuts';
import MarkdownPreview from '~/behaviors/preview_markdown';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';

const mockSearchInput = document.createElement('input');

jest.mock('~/lib/utils/dom_utils', () => ({
  waitForElement: jest.fn(() => Promise.resolve(mockSearchInput)),
}));

describe('Shortcuts', () => {
  let shortcuts;

  beforeAll(() => {
    shortcuts = new Shortcuts();
  });

  const mockSuperSidebarSearchButton = () => {
    const button = document.createElement('button');
    button.id = 'super-sidebar-search';
    return button;
  };

  beforeEach(() => {
    setHTMLFixture(htmlSnippetsShow);
    document.body.appendChild(mockSuperSidebarSearchButton());

    new Shortcuts(); // eslint-disable-line no-new
    new MarkdownPreview(); // eslint-disable-line no-new

    jest.spyOn(HTMLElement.prototype, 'click');

    jest.spyOn(Mousetrap.prototype, 'stopCallback');
    jest.spyOn(Mousetrap.prototype, 'bind').mockImplementation();
    jest.spyOn(Mousetrap.prototype, 'unbind').mockImplementation();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('does not allow subclassing', () => {
    const createSubclass = () => {
      class Subclass extends Shortcuts {}

      return new Subclass();
    };

    expect(createSubclass).toThrow(/cannot be subclassed/);
  });

  describe('markdown shortcuts', () => {
    let shortcutElements;

    beforeEach(() => {
      // Get all shortcuts specified with md-shortcuts attributes in the fixture.
      // `shortcuts` will look something like this:
      // [
      //   [ 'mod+b' ],
      //   [ 'mod+i' ],
      //   [ 'mod+k' ]
      // ]
      shortcutElements = $('.edit-note .js-md')
        .map(function getShortcutsFromToolbarBtn() {
          const mdShortcuts = $(this).data('md-shortcuts');

          // jQuery.map() automatically unwraps arrays, so we
          // have to double wrap the array to counteract this
          return mdShortcuts ? [mdShortcuts] : undefined;
        })
        .get();
    });

    describe('initMarkdownEditorShortcuts', () => {
      let $textarea;
      let localMousetrapInstance;

      beforeEach(() => {
        $textarea = $('.edit-note textarea');
        Shortcuts.initMarkdownEditorShortcuts($textarea);
        localMousetrapInstance = $textarea.data(LOCAL_MOUSETRAP_DATA_KEY);
      });

      it('attaches a Mousetrap handler for every markdown shortcut specified with md-shortcuts', () => {
        const expectedCalls = shortcutElements.map((s) => [s, expect.any(Function)]);

        expect(Mousetrap.prototype.bind.mock.calls).toEqual(expectedCalls);
      });

      it('attaches a stopCallback that allows each markdown shortcut specified with md-shortcuts', () => {
        flatten(shortcutElements).forEach((s) => {
          expect(
            localMousetrapInstance.stopCallback.call(localMousetrapInstance, null, null, s),
          ).toBe(false);
        });
      });
    });

    describe('removeMarkdownEditorShortcuts', () => {
      it('does nothing if initMarkdownEditorShortcuts was not previous called', () => {
        Shortcuts.removeMarkdownEditorShortcuts($('.edit-note textarea'));

        expect(Mousetrap.prototype.unbind.mock.calls).toEqual([]);
      });

      it('removes Mousetrap handlers for every markdown shortcut specified with md-shortcuts', () => {
        Shortcuts.initMarkdownEditorShortcuts($('.edit-note textarea'));
        Shortcuts.removeMarkdownEditorShortcuts($('.edit-note textarea'));

        const expectedCalls = shortcutElements.map((s) => [s]);

        expect(Mousetrap.prototype.unbind.mock.calls).toEqual(expectedCalls);
      });
    });
  });

  describe('focusSearch', () => {
    let event;
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(() => {
      event = new KeyboardEvent('keydown', { cancelable: true });
      Shortcuts.focusSearch(event);
    });

    it('clicks the super sidebar search button', () => {
      expect(HTMLElement.prototype.click).toHaveBeenCalled();
      const thisArg = HTMLElement.prototype.click.mock.contexts[0];
      expect(thisArg.id).toBe('super-sidebar-search');
    });

    it('cancels the default behaviour of the event', () => {
      expect(event.defaultPrevented).toBe(true);
    });

    it('triggers internal_event tracking', () => {
      const { trackEventSpy } = bindInternalEventDocument(document.body);
      expect(trackEventSpy).toHaveBeenCalledWith(
        'press_keyboard_shortcut_to_activate_command_palette',
      );
    });
  });

  describe('focusSearchFile', () => {
    let event;
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(() => {
      jest.spyOn(mockSearchInput, 'dispatchEvent');
      event = new KeyboardEvent('keydown', { cancelable: true });
      Shortcuts.focusSearchFile(event);
    });

    it('clicks the super sidebar search button', () => {
      expect(HTMLElement.prototype.click).toHaveBeenCalled();
      expect(HTMLElement.prototype.click.mock.contexts[0].id).toBe('super-sidebar-search');
    });

    it('cancels the default behavior of the event', () => {
      expect(event.defaultPrevented).toBe(true);
    });

    it('waits for the input to become available in the DOM', () => {
      expect(waitForElement).toHaveBeenCalledWith('#super-sidebar-search-modal #search');
    });

    it('sets the value of the search input', () => {
      expect(mockSearchInput.value).toBe('~');
    });

    it('dispatches an `input` event on the search input', () => {
      expect(mockSearchInput.dispatchEvent).toHaveBeenCalledWith(new Event('input'));
    });

    it('triggers internal_event tracking', () => {
      jest.spyOn(mockSearchInput, 'dispatchEvent');
      event = new KeyboardEvent('keydown', { key: 't' }, { cancelable: true });
      Shortcuts.focusSearchFile(event);
      const { trackEventSpy } = bindInternalEventDocument(document.body);

      expect(trackEventSpy).toHaveBeenCalledWith('click_go_to_file_shortcut');
    });

    it('prefils current path from breadcrumbs', async () => {
      setHTMLFixture('<div class="js-repo-breadcrumbs" data-current-path="files/test"></div>');

      event = new KeyboardEvent('keydown', { cancelable: true });
      await Shortcuts.focusSearchFile(event);

      expect(mockSearchInput.value).toBe('~files/test/');
    });
  });

  describe('adding shortcuts', () => {
    it('add calls Mousetrap.bind correctly', () => {
      const mockCommand = { defaultKeys: ['m'] };
      const mockCallback = () => {};

      shortcuts.add(mockCommand, mockCallback);

      expect(Mousetrap.prototype.bind).toHaveBeenCalledTimes(1);
      const [callArguments] = Mousetrap.prototype.bind.mock.calls;
      expect(callArguments[0]).toEqual(mockCommand.defaultKeys);
      expect(callArguments[1]).toBe(mockCallback);
    });

    it('addAll calls Mousetrap.bind correctly', () => {
      const mockCommandsAndCallbacks = [
        [{ defaultKeys: ['1'] }, () => {}],
        [{ defaultKeys: ['2'] }, () => {}],
      ];

      shortcuts.addAll(mockCommandsAndCallbacks);

      expect(Mousetrap.prototype.bind).toHaveBeenCalledTimes(mockCommandsAndCallbacks.length);
      const { calls } = Mousetrap.prototype.bind.mock;

      mockCommandsAndCallbacks.forEach(([mockCommand, mockCallback], i) => {
        expect(calls[i][0]).toEqual(mockCommand.defaultKeys);
        expect(calls[i][1]).toBe(mockCallback);
      });
    });
  });

  describe('addExtension', () => {
    it('instantiates the given extension', () => {
      const MockExtension = jest.fn();

      const returnValue = shortcuts.addExtension(MockExtension, ['foo']);

      expect(MockExtension).toHaveBeenCalledTimes(1);
      expect(MockExtension).toHaveBeenCalledWith(shortcuts, 'foo');
      expect(returnValue).toBe(MockExtension.mock.instances[0]);
    });

    it('instantiates declared dependencies', () => {
      const MockDependency = jest.fn();
      const MockExtension = jest.fn();

      MockExtension.dependencies = [MockDependency];

      const returnValue = shortcuts.addExtension(MockExtension, ['foo']);

      expect(MockDependency).toHaveBeenCalledTimes(1);
      expect(MockDependency.mock.instances).toHaveLength(1);
      expect(MockDependency).toHaveBeenCalledWith(shortcuts);

      expect(returnValue).toBe(MockExtension.mock.instances[0]);
    });

    it('does not instantiate an extension more than once', () => {
      const MockExtension = jest.fn();

      const returnValue = shortcuts.addExtension(MockExtension, ['foo']);
      const secondReturnValue = shortcuts.addExtension(MockExtension, ['bar']);

      expect(MockExtension).toHaveBeenCalledTimes(1);
      expect(MockExtension).toHaveBeenCalledWith(shortcuts, 'foo');
      expect(returnValue).toBe(MockExtension.mock.instances[0]);
      expect(secondReturnValue).toBe(MockExtension.mock.instances[0]);
    });

    it('allows extensions to redundantly depend on Shortcuts', () => {
      const MockExtension = jest.fn();
      MockExtension.dependencies = [Shortcuts];

      shortcuts.addExtension(MockExtension);

      expect(MockExtension).toHaveBeenCalledTimes(1);
      expect(MockExtension).toHaveBeenCalledWith(shortcuts);

      // Ensure it wasn't instantiated
      expect(shortcuts.extensions.has(Shortcuts)).toBe(false);
    });

    it('allows extensions to incorrectly depend on themselves', () => {
      const A = jest.fn();
      A.dependencies = [A];
      shortcuts.addExtension(A);
      expect(A).toHaveBeenCalledTimes(1);
      expect(A).toHaveBeenCalledWith(shortcuts);
    });

    it('handles extensions with circular dependencies', () => {
      const A = jest.fn();
      const B = jest.fn();
      const C = jest.fn();

      A.dependencies = [B];
      B.dependencies = [C];
      C.dependencies = [A];

      shortcuts.addExtension(A);

      expect(A).toHaveBeenCalledTimes(1);
      expect(B).toHaveBeenCalledTimes(1);
      expect(C).toHaveBeenCalledTimes(1);
    });

    it('handles complex (diamond) dependency graphs', () => {
      const X = jest.fn();
      const A = jest.fn();
      const C = jest.fn();
      const D = jest.fn();
      const E = jest.fn();

      // Form this dependency graph:
      //
      // X ───► A ───► C
      // │             ▲
      // └────► D ─────┘
      //        │
      //        └────► E
      X.dependencies = [A, D];
      A.dependencies = [C];
      D.dependencies = [C, E];

      shortcuts.addExtension(X);

      expect(X).toHaveBeenCalledTimes(1);
      expect(A).toHaveBeenCalledTimes(1);
      expect(C).toHaveBeenCalledTimes(1);
      expect(D).toHaveBeenCalledTimes(1);
      expect(E).toHaveBeenCalledTimes(1);
    });
  });
});

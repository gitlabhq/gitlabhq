import $ from 'jquery';
import { flatten } from 'lodash';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';

const mockMousetrap = {
  bind: jest.fn(),
  unbind: jest.fn(),
};

jest.mock('mousetrap', () => {
  return jest.fn().mockImplementation(() => mockMousetrap);
});

jest.mock('mousetrap/plugins/pause/mousetrap-pause', () => {});

describe('Shortcuts', () => {
  const fixtureName = 'snippets/show.html';
  const createEvent = (type, target) =>
    $.Event(type, {
      target,
    });

  beforeEach(() => {
    loadFixtures(fixtureName);

    jest.spyOn(document.querySelector('.js-new-note-form .js-md-preview-button'), 'focus');
    jest.spyOn(document.querySelector('.edit-note .js-md-preview-button'), 'focus');

    new Shortcuts(); // eslint-disable-line no-new
  });

  describe('toggleMarkdownPreview', () => {
    it('focuses preview button in form', () => {
      Shortcuts.toggleMarkdownPreview(
        createEvent('KeyboardEvent', document.querySelector('.js-new-note-form .js-note-text')),
      );

      expect(
        document.querySelector('.js-new-note-form .js-md-preview-button').focus,
      ).toHaveBeenCalled();
    });

    it('focues preview button inside edit comment form', () => {
      document.querySelector('.js-note-edit').click();

      Shortcuts.toggleMarkdownPreview(
        createEvent('KeyboardEvent', document.querySelector('.edit-note .js-note-text')),
      );

      expect(
        document.querySelector('.js-new-note-form .js-md-preview-button').focus,
      ).not.toHaveBeenCalled();
      expect(document.querySelector('.edit-note .js-md-preview-button').focus).toHaveBeenCalled();
    });
  });

  describe('markdown shortcuts', () => {
    let shortcuts;

    beforeEach(() => {
      // Get all shortcuts specified with md-shortcuts attributes in the fixture.
      // `shortcuts` will look something like this:
      // [
      //   [ 'mod+b' ],
      //   [ 'mod+i' ],
      //   [ 'mod+k' ]
      // ]
      shortcuts = $('.edit-note .js-md')
        .map(function getShortcutsFromToolbarBtn() {
          const mdShortcuts = $(this).data('md-shortcuts');

          // jQuery.map() automatically unwraps arrays, so we
          // have to double wrap the array to counteract this:
          // https://stackoverflow.com/a/4875669/1063392
          return mdShortcuts ? [mdShortcuts] : undefined;
        })
        .get();
    });

    describe('initMarkdownEditorShortcuts', () => {
      beforeEach(() => {
        Shortcuts.initMarkdownEditorShortcuts($('.edit-note textarea'));
      });

      it('attaches a Mousetrap handler for every markdown shortcut specified with md-shortcuts', () => {
        const expectedCalls = shortcuts.map((s) => [s, expect.any(Function)]);

        expect(mockMousetrap.bind.mock.calls).toEqual(expectedCalls);
      });

      it('attaches a stopCallback that allows each markdown shortcut specified with md-shortcuts', () => {
        flatten(shortcuts).forEach((s) => {
          expect(mockMousetrap.stopCallback(null, null, s)).toBe(false);
        });
      });
    });

    describe('removeMarkdownEditorShortcuts', () => {
      it('does nothing if initMarkdownEditorShortcuts was not previous called', () => {
        Shortcuts.removeMarkdownEditorShortcuts($('.edit-note textarea'));

        expect(mockMousetrap.unbind.mock.calls).toEqual([]);
      });

      it('removes Mousetrap handlers for every markdown shortcut specified with md-shortcuts', () => {
        Shortcuts.initMarkdownEditorShortcuts($('.edit-note textarea'));
        Shortcuts.removeMarkdownEditorShortcuts($('.edit-note textarea'));

        const expectedCalls = shortcuts.map((s) => [s]);

        expect(mockMousetrap.unbind.mock.calls).toEqual(expectedCalls);
      });
    });
  });
});

import $ from 'jquery';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';

describe('Shortcuts', () => {
  const fixtureName = 'snippets/show.html';
  const createEvent = (type, target) =>
    $.Event(type, {
      target,
    });

  preloadFixtures(fixtureName);

  describe('toggleMarkdownPreview', () => {
    beforeEach(() => {
      loadFixtures(fixtureName);

      jest.spyOn(document.querySelector('.js-new-note-form .js-md-preview-button'), 'focus');
      jest.spyOn(document.querySelector('.edit-note .js-md-preview-button'), 'focus');

      new Shortcuts(); // eslint-disable-line no-new
    });

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
});

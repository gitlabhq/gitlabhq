import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Dropzone from 'dropzone';
import $ from 'jquery';
import Mousetrap from 'mousetrap';
import initNotes from '~/init_notes';
import * as utils from '~/lib/utils/common_utils';
import ZenMode from '~/zen_mode';

describe('ZenMode', () => {
  let mock;
  let zen;
  let dropzoneForElementSpy;
  const fixtureName = 'snippets/show.html';

  function enterZen() {
    $('.notes-form .js-zen-enter').click();
  }

  function exitZen() {
    $('.notes-form .js-zen-leave').click();
  }

  function escapeKeydown() {
    $('.notes-form textarea').trigger(
      $.Event('keydown', {
        keyCode: 27,
      }),
    );
  }

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet().reply(200);

    loadFixtures(fixtureName);
    initNotes();

    dropzoneForElementSpy = jest.spyOn(Dropzone, 'forElement').mockImplementation(() => ({
      enable: () => true,
    }));
    zen = new ZenMode();

    // Set this manually because we can't actually scroll the window
    zen.scroll_position = 456;
  });

  describe('enabling dropzone', () => {
    beforeEach(() => {
      enterZen();
    });

    it('should not call dropzone if element is not dropzone valid', () => {
      $('.div-dropzone').addClass('js-invalid-dropzone');
      exitZen();

      expect(dropzoneForElementSpy.mock.calls.length).toEqual(0);
    });

    it('should call dropzone if element is dropzone valid', () => {
      $('.div-dropzone').removeClass('js-invalid-dropzone');
      exitZen();

      expect(dropzoneForElementSpy.mock.calls.length).toEqual(2);
    });
  });

  describe('on enter', () => {
    it('pauses Mousetrap', () => {
      const mouseTrapPauseSpy = jest.spyOn(Mousetrap, 'pause');
      enterZen();

      expect(mouseTrapPauseSpy).toHaveBeenCalled();
    });

    it('removes textarea styling', () => {
      $('.notes-form textarea').attr('style', 'height: 400px');
      enterZen();

      expect($('.notes-form textarea')).not.toHaveAttr('style');
    });
  });

  describe('in use', () => {
    beforeEach(enterZen);

    it('exits on Escape', () => {
      escapeKeydown();

      expect($('.notes-form .zen-backdrop')).not.toHaveClass('fullscreen');
    });
  });

  describe('on exit', () => {
    beforeEach(enterZen);

    it('unpauses Mousetrap', () => {
      const mouseTrapUnpauseSpy = jest.spyOn(Mousetrap, 'unpause');
      exitZen();

      expect(mouseTrapUnpauseSpy).toHaveBeenCalled();
    });

    it('restores the scroll position', () => {
      jest.spyOn(utils, 'scrollToElement');
      exitZen();

      expect(utils.scrollToElement).toHaveBeenCalled();
    });
  });
});

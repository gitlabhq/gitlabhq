import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Dropzone from 'dropzone';
import $ from 'jquery';
import htmlSnippetsShow from 'test_fixtures/snippets/show.html';
import { Mousetrap } from '~/lib/mousetrap';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import GLForm from '~/gl_form';
import * as utils from '~/lib/utils/common_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import ZenMode from '~/zen_mode';

describe('ZenMode', () => {
  let mock;
  let zen;
  let dropzoneForElementSpy;

  const getTextarea = () => $('.notes-form textarea');

  function enterZen() {
    $('.notes-form .js-zen-enter').click();
  }

  function exitZen() {
    $('.notes-form .js-zen-leave').click();
  }

  function escapeKeydown() {
    getTextarea().trigger(
      $.Event('keydown', {
        keyCode: 27,
      }),
    );
  }

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet().reply(HTTP_STATUS_OK);

    setHTMLFixture(htmlSnippetsShow);

    const form = $('.js-new-note-form');
    new GLForm(form); // eslint-disable-line no-new

    dropzoneForElementSpy = jest.spyOn(Dropzone, 'forElement').mockImplementation(() => ({
      enable: () => true,
    }));
    zen = new ZenMode();

    // Set this manually because we can't actually scroll the window
    zen.scroll_position = 456;
  });

  afterEach(() => {
    $(document).off('click', '.js-zen-enter');
    $(document).off('click', '.js-zen-leave');
    $(document).off('zen_mode:enter');
    $(document).off('zen_mode:leave');
    $(document).off('keydown');

    resetHTMLFixture();
  });

  describe('enabling dropzone', () => {
    beforeEach(() => {
      enterZen();
    });

    it('should not call dropzone if element is not dropzone valid', () => {
      $('.div-dropzone').addClass('js-invalid-dropzone');
      exitZen();

      expect(dropzoneForElementSpy).not.toHaveBeenCalled();
    });

    it('should call dropzone if element is dropzone valid', () => {
      $('.div-dropzone').removeClass('js-invalid-dropzone');
      exitZen();

      expect(dropzoneForElementSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe('on enter', () => {
    it('pauses Mousetrap', () => {
      const mouseTrapPauseSpy = jest.spyOn(Mousetrap, 'pause');
      enterZen();

      expect(mouseTrapPauseSpy).toHaveBeenCalled();
    });

    it('removes textarea styling', () => {
      getTextarea().attr('style', 'height: 400px');
      enterZen();

      expect(getTextarea()).not.toHaveAttr('style');
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

  it('restores textarea style', () => {
    const style = 'color: red; overflow-y: hidden;';
    getTextarea().attr('style', style);
    expect(getTextarea()).toHaveAttr('style', style);

    enterZen();
    exitZen();

    expect(getTextarea()).toHaveAttr('style', style);
  });
});

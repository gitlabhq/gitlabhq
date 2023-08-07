import { initToastMessages } from '~/behaviors/toasts';
import { setHTMLFixture } from 'helpers/fixtures';
import showToast from '~/vue_shared/plugins/global_toast';

jest.mock('~/vue_shared/plugins/global_toast');

describe('initToastMessages', () => {
  describe('when there are no messages', () => {
    beforeEach(() => {
      setHTMLFixture('<div></div>');

      initToastMessages();
    });

    it('does not display any toasts', () => {
      expect(showToast).not.toHaveBeenCalled();
    });
  });

  describe('when there is a message', () => {
    const expectedMessage = 'toast with jam is great';

    beforeEach(() => {
      setHTMLFixture(
        `<div>
           <div class="js-toast-message" data-message="${expectedMessage}"></div>
         </div>`,
      );

      initToastMessages();
    });

    it('displays the message', () => {
      expect(showToast).toHaveBeenCalledTimes(1);
      expect(showToast).toHaveBeenCalledWith(expectedMessage);
    });
  });

  describe('when there are multiple messages', () => {
    beforeEach(() => {
      setHTMLFixture(
        `<div>
            <div class="js-toast-message" data-message="foo"></div>
            <div class="js-toast-message" data-message="bar"></div>
            <div class="js-toast-message" data-message="baz"></div>
         </div>`,
      );

      initToastMessages();
    });

    it('displays the messages', () => {
      expect(showToast).toHaveBeenCalledTimes(3);
      expect(showToast).toHaveBeenCalledWith('foo');
      expect(showToast).toHaveBeenCalledWith('bar');
      expect(showToast).toHaveBeenCalledWith('baz');
    });
  });
});

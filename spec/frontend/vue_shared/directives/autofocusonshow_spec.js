import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';

/**
 * We're testing this directive's hooks as pure functions
 * since behaviour of this directive is highly-dependent
 * on underlying DOM methods.
 */
describe('AutofocusOnShow directive', () => {
  describe('with input invisible on component render', () => {
    let el;

    beforeEach(() => {
      setHTMLFixture('<div id="container" style="display: none;"><input id="inputel"/></div>');
      el = document.querySelector('#inputel');
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('should bind IntersectionObserver on input element', () => {
      jest.spyOn(el, 'focus').mockImplementation(() => {});

      autofocusonshow.inserted(el);

      expect(el.visibilityObserver).toBeDefined();
      expect(el.focus).not.toHaveBeenCalled();
    });

    it('should stop IntersectionObserver on input element on unbind hook', () => {
      el.visibilityObserver = {
        disconnect: () => {},
      };
      jest.spyOn(el.visibilityObserver, 'disconnect').mockImplementation(() => {});

      autofocusonshow.unbind(el);

      expect(el.visibilityObserver).toBeDefined();
      expect(el.visibilityObserver.disconnect).toHaveBeenCalled();
    });
  });
});

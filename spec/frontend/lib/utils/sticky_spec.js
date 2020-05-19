import { isSticky } from '~/lib/utils/sticky';
import { setHTMLFixture } from 'helpers/fixtures';

const TEST_OFFSET_TOP = 500;

describe('sticky', () => {
  let el;
  let offsetTop;

  beforeEach(() => {
    setHTMLFixture(
      `
      <div class="parent">
        <div id="js-sticky"></div>
      </div>
    `,
    );

    offsetTop = TEST_OFFSET_TOP;
    el = document.getElementById('js-sticky');
    Object.defineProperty(el, 'offsetTop', {
      get() {
        return offsetTop;
      },
    });
  });

  afterEach(() => {
    el = null;
  });

  describe('when stuck', () => {
    it('does not remove is-stuck class', () => {
      isSticky(el, 0, el.offsetTop);
      isSticky(el, 0, el.offsetTop);

      expect(el.classList.contains('is-stuck')).toBeTruthy();
    });

    it('adds is-stuck class', () => {
      isSticky(el, 0, el.offsetTop);

      expect(el.classList.contains('is-stuck')).toBeTruthy();
    });

    it('inserts placeholder element', () => {
      isSticky(el, 0, el.offsetTop, true);

      expect(document.querySelector('.sticky-placeholder')).not.toBeNull();
    });
  });

  describe('when not stuck', () => {
    it('removes is-stuck class', () => {
      jest.spyOn(el.classList, 'remove');

      isSticky(el, 0, el.offsetTop);
      isSticky(el, 0, 0);

      expect(el.classList.remove).toHaveBeenCalledWith('is-stuck');
      expect(el.classList.contains('is-stuck')).toBe(false);
    });

    it('does not add is-stuck class', () => {
      isSticky(el, 0, 0);

      expect(el.classList.contains('is-stuck')).toBeFalsy();
    });

    it('removes placeholder', () => {
      isSticky(el, 0, el.offsetTop, true);
      isSticky(el, 0, 0, true);

      expect(document.querySelector('.sticky-placeholder')).toBeNull();
    });
  });
});

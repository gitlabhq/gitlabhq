import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initPortraitLogoDetection } from '~/logo';

describe('initPortraitLogoDetection', () => {
  let img;

  const loadImage = () => {
    const loadEvent = new Event('load');
    img.dispatchEvent(loadEvent);
  };

  beforeEach(() => {
    setHTMLFixture('<img class="gl-invisible gl-h-10 js-portrait-logo-detection" />');
    initPortraitLogoDetection();
    img = document.querySelector('img');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when logo does not have portrait format', () => {
    beforeEach(() => {
      img.height = 10;
      img.width = 10;
    });

    it('removes gl-invisible', () => {
      expect(img.classList).toContain('gl-invisible');
      expect(img.classList).toContain('gl-h-10');

      loadImage();

      expect(img.classList).not.toContain('gl-invisible');
      expect(img.classList).toContain('gl-h-10');
    });
  });

  describe('when logo has portrait format', () => {
    beforeEach(() => {
      img.height = 11;
      img.width = 10;
    });

    it('removes gl-invisible', () => {
      expect(img.classList).toContain('gl-invisible');
      expect(img.classList).toContain('gl-h-10');

      loadImage();

      expect(img.classList).not.toContain('gl-invisible');
      expect(img.classList).toContain('gl-w-10');
    });
  });
});

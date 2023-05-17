import SketchLoader from '~/blob/sketch';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import htmlSketchViewer from 'test_fixtures_static/sketch_viewer.html';

describe('Sketch viewer', () => {
  beforeEach(() => {
    setHTMLFixture(htmlSketchViewer);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('with error message', () => {
    beforeEach(() => {
      jest.spyOn(SketchLoader.prototype, 'getZipContents').mockImplementation(
        () =>
          new Promise((resolve, reject) => {
            reject();
          }),
      );

      return new SketchLoader(document.getElementById('js-sketch-viewer'));
    });

    it('renders error message', () => {
      expect(document.querySelector('#js-sketch-viewer p')).not.toBeNull();

      expect(document.querySelector('#js-sketch-viewer p').textContent.trim()).toContain(
        'Cannot show preview.',
      );
    });

    it('removes the loading icon', () => {
      expect(document.querySelector('.js-loading-icon')).toBeNull();
    });
  });

  describe('success', () => {
    beforeEach(() => {
      jest.spyOn(SketchLoader.prototype, 'getZipContents').mockResolvedValue({
        files: {
          'previews/preview.png': {
            async: jest.fn().mockResolvedValue('foo'),
          },
        },
      });
      // eslint-disable-next-line no-new
      new SketchLoader(document.getElementById('js-sketch-viewer'));

      return waitForPromises();
    });

    it('does not render error message', () => {
      expect(document.querySelector('#js-sketch-viewer p')).toBeNull();
    });

    it('removes the loading icon', () => {
      expect(document.querySelector('.js-loading-icon')).toBeNull();
    });

    it('renders preview img', () => {
      const img = document.querySelector('#js-sketch-viewer img');

      expect(img).not.toBeNull();
      expect(img.classList.contains('img-fluid')).toBe(true);
    });

    it('renders link to image', () => {
      const img = document.querySelector('#js-sketch-viewer img');
      const link = document.querySelector('#js-sketch-viewer a');

      expect(link.href).toBe(img.src);
      expect(link.target).toBe('_blank');
    });
  });
});

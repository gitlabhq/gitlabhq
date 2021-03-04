import JSZip from 'jszip';
import SketchLoader from '~/blob/sketch';

jest.mock('jszip');

describe('Sketch viewer', () => {
  beforeEach(() => {
    loadFixtures('static/sketch_viewer.html');
  });

  describe('with error message', () => {
    beforeEach((done) => {
      jest.spyOn(SketchLoader.prototype, 'getZipFile').mockImplementation(
        () =>
          new Promise((resolve, reject) => {
            reject();
            done();
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
    beforeEach((done) => {
      const loadAsyncMock = {
        files: {
          'previews/preview.png': {
            async: jest.fn(),
          },
        },
      };

      loadAsyncMock.files['previews/preview.png'].async.mockImplementation(
        () =>
          new Promise((resolve) => {
            resolve('foo');
            done();
          }),
      );

      jest.spyOn(SketchLoader.prototype, 'getZipFile').mockResolvedValue();
      jest.spyOn(JSZip, 'loadAsync').mockResolvedValue(loadAsyncMock);
      return new SketchLoader(document.getElementById('js-sketch-viewer'));
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
      expect(img.classList.contains('img-fluid')).toBeTruthy();
    });

    it('renders link to image', () => {
      const img = document.querySelector('#js-sketch-viewer img');
      const link = document.querySelector('#js-sketch-viewer a');

      expect(link.href).toBe(img.src);
      expect(link.target).toBe('_blank');
    });
  });
});

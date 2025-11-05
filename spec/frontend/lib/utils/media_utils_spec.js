// eslint-disable-next-line max-classes-per-file
import fs from 'fs';
import { getMediaDimensions, getLimitedMediaDimensions } from '~/lib/utils/media_utils';

const retinaImage = fs.readFileSync('spec/fixtures/retina_image.png');
const nonRetinaImage = fs.readFileSync('spec/fixtures/non_retina_image.png');
const gif = fs.readFileSync('spec/fixtures/banana_sample.gif');
const notAPng = fs.readFileSync('spec/fixtures/not_a_png.png');

const fallbackDimensions = { width: 500, height: 5000 };
const videoDimensions = { width: 1920, height: 1080 };

class FakeValidImage extends EventTarget {
  width = fallbackDimensions.width;
  height = fallbackDimensions.height;

  set src(value) {
    this.dispatchEvent(new CustomEvent('load'));
  }
}

class FakeInvalidImage extends EventTarget {
  width = 0;
  height = 0;

  set src(value) {
    this.dispatchEvent(new ErrorEvent('error'));
  }
}

class FakeVideo extends EventTarget {
  videoWidth = videoDimensions.width;
  videoHeight = videoDimensions.height;
  preload = '';

  set src(value) {
    this.dispatchEvent(new CustomEvent('loadedmetadata'));
  }
}

class FakeSlowVideo extends EventTarget {
  videoWidth = videoDimensions.width;
  videoHeight = videoDimensions.height;
  preload = '';

  // eslint-disable-next-line class-methods-use-this
  set src(value) {
    // Never fires loadedmetadata - will trigger timeout
  }
}

describe('media utils', () => {
  describe('getMediaDimensions', () => {
    describe('images', () => {
      describe('with valid images', () => {
        beforeEach(() => {
          jest.spyOn(window, 'Image').mockImplementation((...args) => new FakeValidImage(...args));
        });

        it.each`
          bytes             | filename                  | mimeType       | description
          ${gif}            | ${'banana_sample.gif'}    | ${'image/gif'} | ${'gif file'}
          ${nonRetinaImage} | ${'non_retina_image.png'} | ${'image/png'} | ${'non-retina image'}
        `('returns fallback dimensions for $description', async ({ bytes, filename, mimeType }) => {
          const file = new File([bytes], filename, { type: mimeType });
          const result = await getMediaDimensions(file);
          expect(result).toStrictEqual(fallbackDimensions);
        });

        it('returns halved dimensions for @2x retina images', async () => {
          const file = new File([nonRetinaImage], 'image@2x.png', { type: 'image/png' });
          const result = await getMediaDimensions(file);
          expect(result).toEqual({
            width: fallbackDimensions.width / 2,
            height: fallbackDimensions.height / 2,
          });
        });

        it('returns the dimensions of a retina PNG image with high PPI', async () => {
          const file = new File([retinaImage], 'retina_image.png', { type: 'image/png' });
          const result = await getMediaDimensions(file);
          expect(result).toEqual({ width: 663, height: 325 });
        });

        it('returns fallback dimensions if PNG parsing fails', async () => {
          const invalidPng = new Uint8Array([
            0x89,
            0x50,
            0x4e,
            0x47, // PNG signature
            0x0d,
            0x0a,
            0x1a,
            0x0a,
            // Invalid/incomplete data after this
          ]);

          const file = new File([invalidPng], 'invalid.png', { type: 'image/png' });
          const result = await getMediaDimensions(file);
          expect(result).toEqual(fallbackDimensions);
        });
      });

      describe('with invalid images', () => {
        beforeEach(() => {
          jest
            .spyOn(window, 'Image')
            .mockImplementation((...args) => new FakeInvalidImage(...args));
        });

        it('returns null for non image file', async () => {
          const file = new File([nonRetinaImage], 'non_retina_image.png', { type: 'text/plain' });
          const result = await getMediaDimensions(file);
          expect(result).toBeNull();
        });

        it('returns null for invalid image file', async () => {
          const file = new File([notAPng], 'not_a_png.png', { type: 'image/png' });
          const result = await getMediaDimensions(file);
          expect(result).toBeNull();
        });
      });
    });

    describe('video', () => {
      let revokeObjectURLSpy;

      beforeEach(() => {
        jest.spyOn(URL, 'createObjectURL').mockReturnValue('blob:mock-url');
        revokeObjectURLSpy = jest.fn();
        Object.defineProperty(URL, 'revokeObjectURL', {
          configurable: true,
          value: revokeObjectURLSpy,
        });
      });

      describe('with valid video files', () => {
        beforeEach(() => {
          jest.spyOn(document, 'createElement').mockImplementation((tag) => {
            if (tag === 'video') return new FakeVideo();
            return document.createElement(tag);
          });
        });

        it('returns video dimensions for valid video files', async () => {
          const file = new File([new Uint8Array([0x00, 0x00])], 'video.mp4', { type: 'video/mp4' });
          const result = await getMediaDimensions(file);
          expect(result).toEqual(videoDimensions);
          expect(revokeObjectURLSpy).toHaveBeenCalled();
        });

        it('returns halved dimensions for @2x retina videos', async () => {
          const file = new File([new Uint8Array([0x00, 0x00])], 'video@2x.mp4', {
            type: 'video/mp4',
          });
          const result = await getMediaDimensions(file);

          expect(result).toEqual({
            width: videoDimensions.width / 2,
            height: videoDimensions.height / 2,
          });
        });
      });

      describe('with invalid video files', () => {
        beforeEach(() => {
          jest.spyOn(document, 'createElement').mockImplementation((tag) => {
            if (tag === 'video') return new FakeSlowVideo();
            return document.createElement(tag);
          });
        });

        it('returns null when video metadata loading times out', async () => {
          const file = new File([new Uint8Array([0x00, 0x00])], 'video.mp4', { type: 'video/mp4' });
          const resultPromise = getMediaDimensions(file);
          jest.runAllTimers();
          const result = await resultPromise;
          expect(result).toBeNull();
          expect(revokeObjectURLSpy).toHaveBeenCalled();
        });
      });
    });
  });

  describe('getLimitedMediaDimensions', () => {
    beforeEach(() => {
      jest.spyOn(window, 'Image').mockImplementation((...args) => new FakeValidImage(...args));
    });

    it('returns null for invalid images', async () => {
      jest.spyOn(window, 'Image').mockImplementation((...args) => new FakeInvalidImage(...args));
      const file = new File([notAPng], 'not_a_png.png', { type: 'image/png' });
      const result = await getLimitedMediaDimensions(file);
      expect(result).toBeNull();
    });

    it('returns null for images with zero or negative dimensions', async () => {
      jest.spyOn(window, 'Image').mockImplementation(() => {
        const img = new FakeValidImage();
        img.width = 0;
        img.height = 0;
        return img;
      });
      const file = new File([nonRetinaImage], 'image.png', { type: 'image/png' });
      const result = await getLimitedMediaDimensions(file);
      expect(result).toBeNull();
    });

    it('returns original dimensions when image is within limits', async () => {
      jest.spyOn(window, 'Image').mockImplementation(() => {
        const img = new FakeValidImage();
        img.width = 800;
        img.height = 500;
        return img;
      });
      const file = new File([nonRetinaImage], 'image.png', { type: 'image/png' });
      const result = await getLimitedMediaDimensions(file);
      expect(result).toEqual({ width: 800, height: 500 });
    });

    it('scales down width when it exceeds the limit', async () => {
      jest.spyOn(window, 'Image').mockImplementation(() => {
        const img = new FakeValidImage();
        img.width = 1800;
        img.height = 400;
        return img;
      });
      const file = new File([nonRetinaImage], 'image.png', { type: 'image/png' });
      const result = await getLimitedMediaDimensions(file);
      expect(result).toEqual({ width: 900, height: 200 });
    });

    it('scales down height when it exceeds the limit', async () => {
      jest.spyOn(window, 'Image').mockImplementation(() => {
        const img = new FakeValidImage();
        img.width = 600;
        img.height = 1200;
        return img;
      });
      const file = new File([nonRetinaImage], 'image.png', { type: 'image/png' });
      const result = await getLimitedMediaDimensions(file);
      expect(result).toEqual({ width: 300, height: 600 });
    });

    it('scales down both dimensions when both exceed limits', async () => {
      jest.spyOn(window, 'Image').mockImplementation(() => {
        const img = new FakeValidImage();
        img.width = 1800;
        img.height = 1200;
        return img;
      });
      const file = new File([nonRetinaImage], 'image.png', { type: 'image/png' });
      const result = await getLimitedMediaDimensions(file);
      expect(result).toEqual({ width: 900, height: 600 });
    });

    it('accepts custom limits', async () => {
      jest.spyOn(window, 'Image').mockImplementation(() => {
        const img = new FakeValidImage();
        img.width = 2000;
        img.height = 1000;
        return img;
      });
      const file = new File([nonRetinaImage], 'image.png', { type: 'image/png' });
      const customLimits = { width: 500, height: 300 };
      const result = await getLimitedMediaDimensions(file, customLimits);
      expect(result).toEqual({ width: 500, height: 250 });
    });

    it('ceils dimensions to avoid fractional pixels', async () => {
      jest.spyOn(window, 'Image').mockImplementation(() => {
        const img = new FakeValidImage();
        img.width = 1000;
        img.height = 333;
        return img;
      });
      const file = new File([nonRetinaImage], 'image.png', { type: 'image/png' });
      const result = await getLimitedMediaDimensions(file);
      expect(result).toEqual({ width: 900, height: 300 });
    });
  });
});

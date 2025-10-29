// eslint-disable-next-line max-classes-per-file
import fs from 'fs';
import { getRetinaDimensions } from '~/lib/utils/image_utils';

const retinaImage = fs.readFileSync('spec/fixtures/retina_image.png');
const nonRetinaImage = fs.readFileSync('spec/fixtures/non_retina_image.png');
const gif = fs.readFileSync('spec/fixtures/banana_sample.gif');
const notAPng = fs.readFileSync('spec/fixtures/not_a_png.png');

const fallbackDimensions = { width: 500, height: 5000 };

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

describe('getRetinaDimensions', () => {
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
      const result = await getRetinaDimensions(file);
      expect(result).toStrictEqual(fallbackDimensions);
    });

    it('returns halved dimensions for @2x retina images', async () => {
      const file = new File([nonRetinaImage], 'image@2x.png', { type: 'image/png' });
      const result = await getRetinaDimensions(file);
      expect(result).toEqual({
        width: fallbackDimensions.width / 2,
        height: fallbackDimensions.height / 2,
      });
    });

    it('returns the dimensions of a retina PNG image with high PPI', async () => {
      const file = new File([retinaImage], 'retina_image.png', { type: 'image/png' });
      const result = await getRetinaDimensions(file);
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
      const result = await getRetinaDimensions(file);
      expect(result).toEqual(fallbackDimensions);
    });
  });

  describe('with invalid images', () => {
    beforeEach(() => {
      jest.spyOn(window, 'Image').mockImplementation((...args) => new FakeInvalidImage(...args));
    });

    it('returns null for non image file', async () => {
      const file = new File([nonRetinaImage], 'non_retina_image.png', { type: 'text/plain' });
      const result = await getRetinaDimensions(file);
      expect(result).toBeNull();
    });

    it('returns null for invalid image file', async () => {
      const file = new File([notAPng], 'not_a_png.png', { type: 'image/png' });
      const result = await getRetinaDimensions(file);
      expect(result).toBeNull();
    });
  });
});

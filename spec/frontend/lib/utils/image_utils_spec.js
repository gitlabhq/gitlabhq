import fs from 'fs';
import { getRetinaDimensions } from '~/lib/utils/image_utils';

const retinaImage = fs.readFileSync('spec/fixtures/retina_image.png');
const nonRetinaImage = fs.readFileSync('spec/fixtures/non_retina_image.png');
const gif = fs.readFileSync('spec/fixtures/banana_sample.gif');
const notAPng = fs.readFileSync('spec/fixtures/not_a_png.png');

describe('getRetinaDimensions', () => {
  it.each`
    bytes             | filename                  | mimeType       | description
    ${gif}            | ${'banana_sample.gif'}    | ${'image/gif'} | ${'gif file'}
    ${notAPng}        | ${'not_a_png.png'}        | ${'image/png'} | ${'file that is not a valid PNG'}
    ${nonRetinaImage} | ${'non_retina_image.png'} | ${'image/png'} | ${'non-retina image'}
  `('returns null if the file is $description', async ({ bytes, filename, mimeType }) => {
    const file = new File([bytes], filename, { type: mimeType });
    const result = await getRetinaDimensions(file);
    expect(result).toBeNull();
  });

  it('returns the dimensions of a retina image', async () => {
    const file = new File([retinaImage], 'retina_image.png', { type: 'image/png' });
    const result = await getRetinaDimensions(file);
    // real dimensions of the image are 1326x650
    expect(result).toEqual({ width: 663, height: 325 });
  });
});

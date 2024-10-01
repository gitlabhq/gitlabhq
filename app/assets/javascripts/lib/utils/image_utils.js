import { domToBlob } from 'modern-screenshot';
import vector from './vector';
import { readFileAsDataURL } from './file_utility';

// 1 meter = 39.3701 inches
const METER_TO_INCHES = 39.3701;
const UNIT_METERS = 1;
const PNG_DEFAULT_PPI = 72;

const stringToUInt32 = (str) => {
  const buffer = str.split('').map((char) => char.charCodeAt(0));
  // eslint-disable-next-line no-bitwise
  return (buffer[0] << 24) + (buffer[1] << 16) + (buffer[2] << 8) + buffer[3];
};

const getPixelsPerInch = (pngImage) => {
  // pHYs is a chunk that specifies the intended pixel size or aspect ratio of the image
  // See https://www.w3.org/TR/PNG-Chunks.html#C.pHYs
  const physPosition = pngImage.indexOf('pHYs');
  if (physPosition === -1) return null;

  // p H Y s   x x x x   y y y y   u
  // - - - -   0 1 2 3   4 5 6 7   8
  //           ^ width   ^ height  ^ unit
  const phys = pngImage.substring(physPosition + 4, physPosition + 4 + 9);
  if (phys.charCodeAt(8) !== UNIT_METERS) return null;

  return vector(phys.substring(0, 4), phys.substring(4, 8))
    .map(stringToUInt32)
    .div(METER_TO_INCHES)
    .round();
};

const fileToPngImage = async (file) => {
  if (file.type !== 'image/png') return null;

  const dataUrl = await readFileAsDataURL(file);
  return atob(dataUrl.split(',')[1]).split('IDAT')[0];
};

export const getRetinaDimensions = async (pngFile) => {
  try {
    const pngImage = await fileToPngImage(pngFile);
    const pixelsPerInch = getPixelsPerInch(pngImage);
    if (pixelsPerInch.lte(PNG_DEFAULT_PPI, PNG_DEFAULT_PPI)) return null;

    // IHDR is the first chunk in a PNG file
    // It contains the image dimensions
    // See https://www.w3.org/TR/PNG-Chunks.html#C.IHDR
    const ihdrPosition = pngImage.substring(0, 30).indexOf('IHDR');
    if (ihdrPosition === -1) return null;

    // I H D R   x x x x   y y y y
    // - - - -   0 1 2 3   4 5 6 7
    //           ^ width   ^ height
    const ihdr = pngImage.substring(ihdrPosition + 4, ihdrPosition + 4 + 8);

    return vector(ihdr.substring(0, 4), ihdr.substring(4, 8))
      .map(stringToUInt32)
      .mul(PNG_DEFAULT_PPI)
      .div(Math.max(pixelsPerInch.x, pixelsPerInch.y))
      .ceil()
      .toSize();
  } catch (e) {
    return null;
  }
};

export function domElementToBlob(domElement) {
  return domToBlob(domElement);
}

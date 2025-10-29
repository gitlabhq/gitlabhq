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

const dataToImage = (data) => {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.addEventListener('load', () => {
      resolve(image);
    });
    image.addEventListener('error', (error) => {
      reject(error);
    });
    image.src = data;
  });
};

const maybe2xRetina = (name) => name.substring(0, name.lastIndexOf('.')).endsWith('@2x');

const getAppleRetinaPngDimensions = (dataUrl) => {
  const data = atob(dataUrl.split(',')[1]).split('IDAT')[0];
  const pixelsPerInch = getPixelsPerInch(data);
  if (pixelsPerInch.lte(PNG_DEFAULT_PPI, PNG_DEFAULT_PPI)) return null;

  // IHDR is the first chunk in a PNG file
  // It contains the image dimensions
  // See https://www.w3.org/TR/PNG-Chunks.html#C.IHDR
  const ihdrPosition = data.substring(0, 30).indexOf('IHDR');
  if (ihdrPosition === -1) return null;

  // I H D R   x x x x   y y y y
  // - - - -   0 1 2 3   4 5 6 7
  //           ^ width   ^ height
  const ihdr = data.substring(ihdrPosition + 4, ihdrPosition + 4 + 8);

  return vector(ihdr.substring(0, 4), ihdr.substring(4, 8))
    .map(stringToUInt32)
    .mul(PNG_DEFAULT_PPI)
    .div(Math.max(pixelsPerInch.x, pixelsPerInch.y))
    .ceil()
    .toSize();
};

export const getRetinaDimensions = async (file) => {
  if (!file.type.startsWith('image/')) return null;

  const data = await readFileAsDataURL(file);
  let image;
  try {
    image = await dataToImage(data);
  } catch (error) {
    return null;
  }

  if (maybe2xRetina(file.name))
    return { width: Math.ceil(image.width / 2), height: Math.ceil(image.height / 2) };

  const fallbackDimensions = { width: image.width, height: image.height };

  if (file.type !== 'image/png') return fallbackDimensions;

  try {
    return getAppleRetinaPngDimensions(data) || fallbackDimensions;
  } catch (e) {
    return fallbackDimensions;
  }
};

export function domElementToBlob(domElement) {
  return domToBlob(domElement);
}

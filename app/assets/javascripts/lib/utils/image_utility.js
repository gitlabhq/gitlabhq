/* eslint-disable import/prefer-default-export */

export function isImageLoaded(element) {
  return element.complete && element.naturalHeight !== 0;
}

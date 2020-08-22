export function isImageLoaded(element) {
  return element.complete && element.naturalHeight !== 0;
}

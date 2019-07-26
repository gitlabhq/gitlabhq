/**
 * Convert hex color to rgb array
 *
 * @param hex string
 * @returns array|null
 */
export const hexToRgb = hex => {
  // Expand shorthand form (e.g. "03F") to full form (e.g. "0033FF")
  const shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i;
  const fullHex = hex.replace(shorthandRegex, (_m, r, g, b) => r + r + g + g + b + b);

  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(fullHex);
  return result
    ? [parseInt(result[1], 16), parseInt(result[2], 16), parseInt(result[3], 16)]
    : null;
};

export const textColorForBackground = backgroundColor => {
  const [r, g, b] = hexToRgb(backgroundColor);

  if (r + g + b > 500) {
    return '#333333';
  }
  return '#FFFFFF';
};

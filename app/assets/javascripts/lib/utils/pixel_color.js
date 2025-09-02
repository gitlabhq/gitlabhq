/**
 * Alpha-weighted average color from raw RGBA pixels.
 * Pixels with alpha below `alphaThreshold` are ignored.
 *
 * @param {Uint8ClampedArray} data - Flat RGBA array: [R,G,B,A, ...]
 * @param {number} [alphaThreshold=16] - Minimum alpha (0–255) to include.
 * @param {string} [fallback='rgb(0, 0, 0)'] - Returned if no pixels qualify.
 * @returns {string} "rgb(r, g, b)" or `fallback`.
 */
export function averageColorFromPixels(data, alphaThreshold = 16, fallback = 'rgb(0, 0, 0)') {
  let r = 0;
  let g = 0;
  let b = 0;
  let w = 0;

  for (let i = 0; i < data.length; i += 4) {
    const a = data[i + 3];
    if (a >= alphaThreshold) {
      const weight = a / 255;
      r += data[i] * weight;
      g += data[i + 1] * weight;
      b += data[i + 2] * weight;
      w += weight;
    }
  }

  if (!w) return fallback;

  const avgR = Math.round(r / w);
  const avgG = Math.round(g / w);
  const avgB = Math.round(b / w);
  return `rgb(${avgR}, ${avgG}, ${avgB})`;
}

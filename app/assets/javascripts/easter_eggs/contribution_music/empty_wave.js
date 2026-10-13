// Background art from Anuja's concept: a twisting ribbon of gray pixels, the sound wave that
// isn't there yet. Full strength for a year with nothing to play, faint behind a song. Static.
const PIXEL = 5;
const PIXEL_GAP = 1;

// All in fractions of the canvas. The two edges cross where the twist folds the ribbon over.
const CENTER = 0.52;
const SWING = 0.17;
const SWING_CYCLES = 0.9;
const THICKNESS = 0.13;
const TWIST_CYCLES = 1.3;
const SCATTER = 0.025;

// Tops out at #4d4b4e, so the message over it keeps AA contrast.
const FRONT = { density: 0.75, colors: ['#4d4b4e'] };
const BACK = { density: 0.45, colors: ['#3a383d', '#4d4b4e'] };
const STRAY = { density: 0.25, colors: ['#3a383d'] };
const HIGHLIGHT_CHANCE = 0.2;

// Deterministic, so the art is the same every time the player opens.
const noise = (x, y, seed) => {
  const n = Math.sin(x * 12.9898 + y * 78.233 + seed * 37.719) * 43758.5453;

  return n - Math.floor(n);
};

const ribbonAt = (x) => {
  const center = CENTER + SWING * Math.sin(2 * Math.PI * SWING_CYCLES * x + 0.6);
  const half = THICKNESS * Math.cos(2 * Math.PI * TWIST_CYCLES * x + 1);

  return { top: center - Math.abs(half), bottom: center + Math.abs(half), isFront: half > 0 };
};

// The face the pixel is on, and how likely it is to be lit there. Brighter mid-band, so the
// ribbon looks rounded, and fading out just past its edges.
const shade = (x, y) => {
  const { top, bottom, isFront } = ribbonAt(x);

  if (y >= top && y <= bottom) {
    const face = isFront ? FRONT : BACK;
    const across = bottom > top ? (y - top) / (bottom - top) : 0.5;

    return { face, density: face.density * (0.6 + 0.4 * Math.sin(Math.PI * across)) };
  }

  const distance = y < top ? top - y : y - bottom;

  return { face: STRAY, density: STRAY.density * Math.exp(-distance / SCATTER) };
};

const paintWave = (canvas, { width, height, pixel }) => {
  const context = canvas.getContext('2d');
  const gap = (PIXEL_GAP * pixel) / PIXEL;
  const columns = Math.ceil(width / pixel);
  const rows = Math.ceil(height / pixel);

  for (let row = 0; row < rows; row += 1) {
    for (let column = 0; column < columns; column += 1) {
      const { face, density } = shade(column / columns, row / rows);

      if (noise(column, row, 1) < density) {
        const isHighlight = face.colors.length > 1 && noise(column, row, 2) < HIGHLIGHT_CHANCE;

        context.fillStyle = face.colors[isHighlight ? 1 : 0];
        context.fillRect(column * pixel, row * pixel, pixel - gap, pixel - gap);
      }
    }
  }
};

export const drawEmptyWave = (canvas) => {
  const ratio = window.devicePixelRatio || 1;
  const width = canvas.clientWidth;
  const height = canvas.clientHeight;
  const context = canvas.getContext('2d');

  canvas.setAttribute('width', width * ratio);
  canvas.setAttribute('height', height * ratio);
  context.setTransform(ratio, 0, 0, ratio, 0, 0);
  context.clearRect(0, 0, width, height);
  paintWave(canvas, { width, height, pixel: PIXEL });
};

// For the video, which draws it every frame.
export const createWaveCanvas = ({ width, height, pixel }) => {
  const canvas = document.createElement('canvas');

  canvas.width = width;
  canvas.height = height;
  paintWave(canvas, { width, height, pixel });

  return canvas;
};

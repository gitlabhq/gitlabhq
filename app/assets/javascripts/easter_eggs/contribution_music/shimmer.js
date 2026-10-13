/* eslint-disable @gitlab/require-i18n-strings -- CSS values only, no user-facing text */
// Busier days take on more of the glow.
export const STRENGTH = [0, 0.45, 0.65, 0.85, 1];

const withAlpha = (hex, alpha) =>
  `${hex}${Math.round(alpha * 255)
    .toString(16)
    .padStart(2, '0')}`;

// From the Playlab palette: https://je-demos-b9df07.gitlab.io/builder/01-palette.html
// A short glow at the playhead's edge, over the brand color each day takes on as the playhead
// crosses it. Oldest end first, so the playhead's own orange is the leading edge.
export const GLOW_COLUMNS = 2;
export const GLOW = [
  { at: 0, color: '#fdf0d5', alpha: 0 },
  { at: 0.6, color: '#f7b951' },
  { at: 1, color: '#fb8017' },
];
const LEADING_COLOR = GLOW.at(-1).color;

// Sweeps the glow across the cell with the brand color right behind it. The color's layer is
// as wide as the whole sweep and moves with the glow's leading edge, so it covers the cell by
// the time the glow has passed; the caller then sets it as the cell's own color.
export const glowCell = (element, { level, color, columnMs, step, reducedMotion }) => {
  if (reducedMotion) {
    return element.animate(
      [{ backgroundColor: withAlpha(LEADING_COLOR, STRENGTH[level]) }, { backgroundColor: color }],
      { duration: columnMs * GLOW_COLUMNS, easing: 'ease-out' },
    );
  }

  const size = element.offsetWidth;
  const trail = GLOW_COLUMNS * step;
  const sweep = size + trail;
  const glow = GLOW.map(
    ({ at, color: stop, alpha = 1 }) => `${withAlpha(stop, alpha * STRENGTH[level])} ${at * 100}%`,
  ).join(', ');
  const layer = {
    backgroundImage: `linear-gradient(to right, ${glow}), linear-gradient(${color}, ${color})`,
    backgroundSize: `${trail}px 100%, ${sweep}px 100%`,
    backgroundRepeat: 'no-repeat',
  };

  return element.animate(
    [
      { ...layer, backgroundPosition: `${-trail}px 0, ${-sweep}px 0` },
      { ...layer, backgroundPosition: `${size}px 0, 0 0` },
    ],
    { duration: (columnMs * sweep) / step },
  );
};

// Canvas version for the video, drawn over a cell that's already filled: its brand color up to
// the playhead, and the glow over that.
export const drawGlow = (canvas, { x, y, size, step, radius, level, color, front }) => {
  const right = Math.min(x + size, front);

  if (right <= x) {
    return;
  }

  const context = canvas.getContext('2d');
  const tail = front - GLOW_COLUMNS * step;
  const glow = context.createLinearGradient(tail, 0, front, 0);

  GLOW.forEach(({ at, color: stop, alpha = 1 }) =>
    glow.addColorStop(at, withAlpha(stop, alpha * STRENGTH[level])),
  );

  context.save();
  context.beginPath();
  context.roundRect(x, y, size, size, radius);
  context.clip();
  context.fillStyle = color;
  context.fillRect(x, y, right - x, size);

  if (right > tail) {
    const left = Math.max(x, tail);

    context.fillStyle = glow;
    context.fillRect(left, y, right - left, size);
  }

  context.restore();
};

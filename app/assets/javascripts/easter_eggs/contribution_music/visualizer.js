const FIRST_BIN = 1;
const BIN_SPAN = 40;
const CLEARANCE = 28;
const BAR_WIDTH = 3;
const BAR_GAP = 2;
const MIN_BAR = 2;

export const FILL_ALPHA = 0.4;

export const prefersReducedMotion = () =>
  window.matchMedia?.(`(prefers-reduced-motion: reduce)`).matches ?? false;

export const drawBars = (
  context,
  spectrum,
  { centerX, centerY, halfWidth, height, clearance, barWidth, barGap },
) => {
  const step = barWidth + barGap;
  const bars = Math.max(Math.floor((halfWidth - clearance) / step), 0);

  context.beginPath();

  for (let bar = 0; bar < bars; bar += 1) {
    const value = spectrum[FIRST_BIN + Math.floor((bar * BIN_SPAN) / bars)] / 255;
    const barHeight = MIN_BAR + value * (height - MIN_BAR);
    const offset = clearance + bar * step;
    const top = centerY - barHeight / 2;

    context.roundRect(centerX + offset, top, barWidth, barHeight, barWidth / 2);
    context.roundRect(centerX - offset - barWidth, top, barWidth, barHeight, barWidth / 2);
  }

  context.fill();
};

export const createVisualizer = (canvas) => {
  const context = canvas.getContext('2d');
  let width = 0;
  let height = 0;

  const resize = () => {
    const ratio = window.devicePixelRatio || 1;

    width = canvas.clientWidth;
    height = canvas.clientHeight;
    canvas.setAttribute('width', width * ratio);
    canvas.setAttribute('height', height * ratio);
    context.setTransform(ratio, 0, 0, ratio, 0, 0);
    context.fillStyle = getComputedStyle(canvas).color;
    context.globalAlpha = FILL_ALPHA;
  };

  const draw = (spectrum) => {
    context.clearRect(0, 0, width, height);
    drawBars(context, spectrum, {
      centerX: width / 2,
      centerY: height / 2,
      halfWidth: width / 2,
      height,
      clearance: CLEARANCE,
      barWidth: BAR_WIDTH,
      barGap: BAR_GAP,
    });
  };

  resize();

  return { draw, resize };
};

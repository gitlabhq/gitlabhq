const MIN_WIDTH_REM = 17;

const pixels = (value) => /^(\d+)(?:px)?$/.exec(value)?.[1];

export const embedStyle = {
  maxWidth: '100%',
  minWidth: `min(${MIN_WIDTH_REM}rem, 100%)`,
};

export const embedMinWidth = (availableWidth) =>
  Math.min(
    MIN_WIDTH_REM * parseFloat(window.getComputedStyle(document.documentElement).fontSize),
    availableWidth,
  );

export const getIframeClasses = (width, height) => [
  'gl-min-w-full gl-border-none',
  { 'gl-inset-0 gl-h-full gl-w-full': !(width || height) },
];

export const getIframeStyle = (width, height) => {
  if (!width && !height) return { maxHeight: '80vh' };

  const pixelWidth = pixels(width);
  const pixelHeight = pixels(height);
  if (!pixelWidth || !pixelHeight) return { maxHeight: '80vh', maxWidth: '100%' };

  return {
    aspectRatio: `${pixelWidth} / ${pixelHeight}`,
    height: 'auto',
    maxHeight: `min(80vh, ${pixelHeight}px)`,
    maxWidth: '100%',
  };
};

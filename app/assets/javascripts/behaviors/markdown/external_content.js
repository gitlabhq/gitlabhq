const MIN_WIDTH_REM = 17;
const DEFAULT_WIDTH = '560';
const DEFAULT_HEIGHT = '315';

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

const cssLength = (value) => (/^\d+$/.test(value) ? `${value}px` : value);

export const embedDimensions = (width, height) =>
  width || height ? { width, height } : { width: DEFAULT_WIDTH, height: DEFAULT_HEIGHT };

export const getIframeStyle = (width, height) => {
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

export const getPlaceholderStyles = (width, height) => {
  const { aspectRatio, maxHeight } = getIframeStyle(width, height);

  return {
    box: {
      width: cssLength(width),
      maxWidth: '100%',
      ...(!aspectRatio && { minHeight: cssLength(height) }),
    },
    spacer: { aspectRatio, maxHeight },
  };
};

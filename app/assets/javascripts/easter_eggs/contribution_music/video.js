import { noop } from 'lodash-es';
import { n__, sprintf, formatNumber } from '~/locale';
import { getMonthNames } from '~/lib/utils/datetime/date_format_utility';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import tanukiSvg from './gitlab-logo-500-rgb.svg?raw';
import logoSvg from './gitlab-logo-200-rgb.svg?raw';
import { encodeQr } from './qr';
import { createPlayer } from './synth';
import { drawBars, FILL_ALPHA } from './visualizer';
import { drawGlow, GLOW_COLUMNS } from './shimmer';
import { createWaveCanvas } from './empty_wave';
import {
  DAYS_IN_THE_WEEK,
  VIDEO_WIDTH,
  VIDEO_HEIGHT,
  VIDEO_FPS,
  VIDEO_TAIL_SECONDS,
  VIDEO_MIME_TYPES,
  VIDEO_THEME,
  BRAND_COLORS,
  WAVE_FAINT_OPACITY,
  WAVE_VISIBLE,
} from './constants';

const PADDING_X = 80;
const SANS = "'GitLab Sans', sans-serif";
const MONO = "'GitLab Mono', monospace";
const LOGO_TOP = 120;
const STAMP_GAP = 24;
const STAMP_SIZE = 22;
const STAMP_ALPHA = 0.7;
const DETAIL_SIZE = 28;
const NAME_SIZE = 64;
const EYEBROW_GAP = 20;
const SUMMARY_GAP = 72;
const SUMMARY_SIZE = 36;
const SUMMARY_LINE_HEIGHT = 1.4;
const CELL_SIZE = 56;
const CELL_GAP = 8;
const CELL_RADIUS = 6;
const GRAPH_HEIGHT = DAYS_IN_THE_WEEK * CELL_SIZE + (DAYS_IN_THE_WEEK - 1) * CELL_GAP;
const EDGE_FADE_WIDTH = 280;
const MONTH_GAP = 12;
const PLAYHEAD_X = VIDEO_WIDTH / 2;
const PLAYHEAD_WIDTH = 2;
const BARS_TOP_GAP = 48;
const BARS_HEIGHT = 120;
const BARS_WIDTH = 6;
const BARS_GAP = 4;
const CHART_REVEAL_MS = 350;
const CHART_REVEAL_STAGGER_MS = 12;
const QR_DROP = 120;
const LOGO_HEIGHT = 40;
// Vertical feeds cover roughly the bottom fifth with captions and buttons, so keep it clear.
const CONTENT_BOTTOM = VIDEO_HEIGHT - 420;
const CARD_DELAY_MS = 400;
// The song view fades out over the first half, then the card fades in over the second.
const CARD_FADE_MS = 800;
const CHART_REVEAL_DELAY_MS = CARD_DELAY_MS + CARD_FADE_MS / 2;
// The total counts up from 0 as the card comes in.
const TOTAL_COUNT_DELAY_MS = CHART_REVEAL_DELAY_MS;
const TOTAL_COUNT_MS = 1500;
// Then the chart sweeps into its brand colors, left to right.
const CARD_RECOLOR_DELAY_MS = TOTAL_COUNT_DELAY_MS + TOTAL_COUNT_MS;
const CARD_RECOLOR_MS = 600;
const AVATAR_SIZE = 120;
const AVATAR_TEXT_GAP = 28;
const BYLINE_GAP = 56;
const CARD_URL_GAP = 40;
const CARD_TOTAL_WEIGHT = 900;
const CARD_TOTAL_MAX_SIZE = 360;
const CARD_TOTAL_LABEL_GAP = 16;
const CARD_TOTAL_GAP = 64;
const CARD_CELL_GAP = 3;
const CARD_CELL_RADIUS = 2;
const QR_MODULE = 6;
const QR_QUIET_ZONE = 4;
const QR_BLOCK_GAP = 1;
const QR_BLOCK_RADIUS = 1.5;
const QR_LOGO_MODULES = 13;
const QR_TANUKI_MODULES = 11;

export class VideoInterruptedError extends Error {}

const pickMimeType = () =>
  window.MediaRecorder && VIDEO_MIME_TYPES.find((type) => MediaRecorder.isTypeSupported(type));

export const isVideoSupported = () =>
  Boolean(pickMimeType() && HTMLCanvasElement.prototype.captureStream);

// Blob URLs keep the canvas origin-clean. Asset URLs can come from a CDN on another origin,
// which would taint the canvas and make captureStream and getImageData throw.
const loadBlob = (blob) =>
  new Promise((resolve, reject) => {
    const src = URL.createObjectURL(blob);
    const image = new Image();
    image.onload = () => {
      URL.revokeObjectURL(src);
      resolve(image);
    };
    image.onerror = (error) => {
      URL.revokeObjectURL(src);
      reject(error);
    };
    image.src = src;
  });

const loadSvg = (svg) => loadBlob(new Blob([svg], { type: 'image/svg+xml' }));

const hexToRgb = (hex) => [1, 3, 5].map((start) => parseInt(hex.slice(start, start + 2), 16));

const TRIM_RESOLUTION = 256;

// The press kit mark has built-in clear space, so find the tanuki itself before sampling it.
const trimToContent = (image) => {
  const canvas = document.createElement('canvas');
  const context = canvas.getContext('2d', { willReadFrequently: true });

  canvas.width = TRIM_RESOLUTION;
  canvas.height = TRIM_RESOLUTION;
  context.drawImage(image, 0, 0, TRIM_RESOLUTION, TRIM_RESOLUTION);

  const { data } = context.getImageData(0, 0, TRIM_RESOLUTION, TRIM_RESOLUTION);
  const bounds = { left: TRIM_RESOLUTION, top: TRIM_RESOLUTION, right: 0, bottom: 0 };

  for (let y = 0; y < TRIM_RESOLUTION; y += 1) {
    for (let x = 0; x < TRIM_RESOLUTION; x += 1) {
      if (data[(y * TRIM_RESOLUTION + x) * 4 + 3] > 0) {
        bounds.left = Math.min(bounds.left, x);
        bounds.top = Math.min(bounds.top, y);
        bounds.right = Math.max(bounds.right, x + 1);
        bounds.bottom = Math.max(bounds.bottom, y + 1);
      }
    }
  }

  return { canvas, ...bounds };
};

// Crops the press kit's built-in clear space, in the image's own coordinates.
const contentBox = (image) => {
  const { left, top, right, bottom } = trimToContent(image);
  const scaleX = image.naturalWidth / TRIM_RESOLUTION;
  const scaleY = image.naturalHeight / TRIM_RESOLUTION;

  return {
    left: left * scaleX,
    top: top * scaleY,
    width: (right - left) * scaleX,
    height: (bottom - top) * scaleY,
  };
};

// Where the wordmark sits on its baseline, as a share of the cropped lockup's height. "GitLab"
// has no descenders, so the lowest ink right of the tanuki is the baseline.
const wordmarkBaseline = (image) => {
  const { canvas, left, top, right, bottom } = trimToContent(image);
  const { data } = canvas.getContext('2d').getImageData(0, 0, TRIM_RESOLUTION, TRIM_RESOLUTION);
  const wordmarkLeft = left + Math.round((right - left) * 0.45);
  let lowest = top;

  for (let y = top; y < bottom; y += 1) {
    for (let x = wordmarkLeft; x < right; x += 1) {
      if (data[(y * TRIM_RESOLUTION + x) * 4 + 3] > 0) {
        lowest = y + 1;
      }
    }
  }

  return (lowest - top) / (bottom - top);
};

// Samples the mark down to a few blocks and snaps each one to the nearest tanuki color.
const pixelate = (image, cells, palette) => {
  const trimmed = trimToContent(image);
  const width = trimmed.right - trimmed.left;
  const height = trimmed.bottom - trimmed.top;
  const scale = cells / Math.max(width, height);
  const canvas = document.createElement('canvas');
  const context = canvas.getContext('2d');
  const swatches = palette.map((hex) => ({ hex, rgb: hexToRgb(hex) }));

  canvas.width = cells;
  canvas.height = cells;
  context.imageSmoothingQuality = 'high';
  context.drawImage(
    trimmed.canvas,
    trimmed.left,
    trimmed.top,
    width,
    height,
    (cells - width * scale) / 2,
    (cells - height * scale) / 2,
    width * scale,
    height * scale,
  );

  const { data } = context.getImageData(0, 0, cells, cells);

  return Array.from({ length: cells * cells }, (_, index) => {
    const [r, g, b, alpha] = data.slice(index * 4, index * 4 + 4);

    if (alpha < 128) {
      return null;
    }

    const distance = ({ rgb }) => (rgb[0] - r) ** 2 + (rgb[1] - g) ** 2 + (rgb[2] - b) ** 2;

    return swatches.reduce((best, swatch) => (distance(swatch) < distance(best) ? swatch : best))
      .hex;
  });
};

const ellipsize = (context, text, width) => {
  if (context.measureText(text).width <= width) {
    return text;
  }

  let end = text.length;

  while (end > 1 && context.measureText(`${text.slice(0, end)}…`).width > width) {
    end -= 1;
  }

  return `${text.slice(0, end)}…`;
};

const wrapLines = (context, text, width) =>
  text.split(' ').reduce((lines, word) => {
    const last = lines.at(-1);
    const candidate = last === undefined ? word : `${last} ${word}`;

    return last === undefined || context.measureText(candidate).width > width
      ? [...lines, word]
      : [...lines.slice(0, -1), candidate];
  }, []);

export const monthLabels = (weeks) =>
  weeks.flatMap((week, weekIndex) => {
    const cell =
      week.find(({ date }) => date?.getDate() === 1) ??
      (weekIndex === 0 && week.find(({ date }) => date));

    return cell ? [{ weekIndex, month: cell.date.getMonth() }] : [];
  });

const drawMonthLabels = (
  canvas,
  labels,
  { left, top, step, fontSize, fontFamily, fill, opacity },
) => {
  const context = canvas.getContext('2d');
  const names = getMonthNames(true);

  context.globalAlpha = opacity;
  context.fillStyle = fill;
  context.font = `${fontSize}px ${fontFamily}`;
  context.textAlign = 'left';
  context.textBaseline = 'top';

  // Walk right to left so a crowded label gives way to the next month, which only
  // happens to the partial month at the start of the year.
  labels.reduceRight((nextX, { weekIndex, month }) => {
    const x = left + weekIndex * step;
    const fits = x + context.measureText(names[month]).width + fontSize / 2 <= nextX;

    if (fits) {
      context.fillText(names[month], x, top);
    }

    return fits ? x : nextX;
  }, Infinity);
};

const easeOutCubic = (t) => 1 - (1 - t) ** 3;
const easeOutQuad = (t) => 1 - (1 - t) ** 2;

const drawGrid = (
  canvas,
  { weeks, cells },
  { left, top, cellSize, gap, radius, opacity = 1, weekOpacity = () => 1, drawCellEffect },
) => {
  const context = canvas.getContext('2d');
  const step = cellSize + gap;

  weeks.forEach((week, weekIndex) => {
    const x = left + weekIndex * step;

    if (x + cellSize < 0 || x > canvas.width) {
      return;
    }

    week.forEach(({ date, level }, dayIndex) => {
      if (!date) {
        return;
      }

      const y = top + dayIndex * step;

      context.globalAlpha = opacity * weekOpacity(weekIndex);
      context.fillStyle = cells[level];
      context.beginPath();
      context.roundRect(x, y, cellSize, cellSize, radius);
      context.fill();

      if (level > 0) {
        drawCellEffect?.(canvas, {
          x,
          y,
          size: cellSize,
          step,
          radius,
          level,
          weekIndex,
          dayIndex,
        });
      }
    });
  });
};

const qrTileSize = (qr) => (qr.length + QR_QUIET_ZONE * 2) * QR_MODULE;

const drawQrTile = (canvas, { qr, tanukiPixels, left, top }) => {
  const context = canvas.getContext('2d');
  const origin = QR_QUIET_ZONE * QR_MODULE;
  const logoStart = (qr.length - QR_LOGO_MODULES) / 2;
  const tanukiStart = (qr.length - QR_TANUKI_MODULES) / 2;
  const inLogo = (row, col) =>
    row >= logoStart &&
    row < logoStart + QR_LOGO_MODULES &&
    col >= logoStart &&
    col < logoStart + QR_LOGO_MODULES;
  const block = (row, col) => {
    context.roundRect(
      left + origin + col * QR_MODULE + QR_BLOCK_GAP / 2,
      top + origin + row * QR_MODULE + QR_BLOCK_GAP / 2,
      QR_MODULE - QR_BLOCK_GAP,
      QR_MODULE - QR_BLOCK_GAP,
      QR_BLOCK_RADIUS,
    );
  };
  // Inverted: the dark modules are drawn light and everything else stays transparent.
  context.fillStyle = VIDEO_THEME.text;
  context.beginPath();
  qr.forEach((row, rowIndex) =>
    row.forEach((dark, colIndex) => {
      if (dark && !inLogo(rowIndex, colIndex)) {
        block(rowIndex, colIndex);
      }
    }),
  );
  context.fill();

  tanukiPixels.forEach((fill, index) => {
    if (fill) {
      context.fillStyle = fill;
      context.beginPath();
      block(
        tanukiStart + Math.floor(index / QR_TANUKI_MODULES),
        tanukiStart + (index % QR_TANUKI_MODULES),
      );
      context.fill();
    }
  });
};

// The video is about three times the size of a phone's modal, so its wave pixels are too.
const WAVE_PIXEL = 15;

const createFrameDrawer = ({
  canvas,
  weeks,
  logo,
  tanuki,
  avatar,
  name,
  username,
  stamp,
  title,
  message,
  url,
}) => {
  const context = canvas.getContext('2d');
  const strip = document.createElement('canvas');
  const stripContext = strip.getContext('2d');
  const grid = { weeks, cells: VIDEO_THEME.cells };
  const wave = createWaveCanvas({ width: VIDEO_WIDTH, height: VIDEO_HEIGHT, pixel: WAVE_PIXEL });
  const textWidth = VIDEO_WIDTH - PADDING_X * 2;
  const summaryLineHeight = SUMMARY_SIZE * SUMMARY_LINE_HEIGHT;
  const graphWidth = weeks.length * (CELL_SIZE + CELL_GAP) - CELL_GAP;
  const logoBox = contentBox(logo);
  const logoWidth = (LOGO_HEIGHT * logoBox.width) / logoBox.height;
  const eyebrowBaseline = LOGO_TOP + wordmarkBaseline(logo) * LOGO_HEIGHT;
  const months = monthLabels(weeks);
  const days = weeks.flat().filter(({ date }) => date);
  const dates = localeDateFormat.asDate.formatRange(days[0].date, days.at(-1).date);
  const monthRowHeight = DETAIL_SIZE + MONTH_GAP;
  const stripHeight = monthRowHeight + GRAPH_HEIGHT;

  strip.width = VIDEO_WIDTH;
  strip.height = stripHeight;

  const setFont = (size, weight = 'normal', family = SANS) => {
    context.font = `${weight} ${size}px ${family}`;
  };

  setFont(SUMMARY_SIZE);
  const summaryLines = wrapLines(context, message, textWidth);

  const bylineTop = LOGO_TOP + LOGO_HEIGHT + BYLINE_GAP;
  const bylineTextLeft = avatar ? PADDING_X + AVATAR_SIZE + AVATAR_TEXT_GAP : PADDING_X;
  const bylineTextWidth = VIDEO_WIDTH - PADDING_X - bylineTextLeft;
  const handle = `@${username}`;

  setFont(NAME_SIZE, 'bold');
  const displayName = ellipsize(context, name ?? handle, bylineTextWidth);
  const summaryY = bylineTop + AVATAR_SIZE + SUMMARY_GAP;
  const textBottom = summaryY + (summaryLines.length - 1) * summaryLineHeight;
  const stripTop =
    (textBottom +
      CONTENT_BOTTOM -
      stripHeight -
      STAMP_GAP -
      STAMP_SIZE -
      BARS_TOP_GAP -
      BARS_HEIGHT) /
    2;
  const graphTop = stripTop + monthRowHeight;
  const stampBaseline = graphTop + GRAPH_HEIGHT + STAMP_GAP + STAMP_SIZE;
  const barsCenterY = stampBaseline + BARS_TOP_GAP + BARS_HEIGHT / 2;

  const cardStep = (textWidth + CARD_CELL_GAP) / weeks.length;
  const cardCellSize = cardStep - CARD_CELL_GAP;
  const cardGraphHeight = DAYS_IN_THE_WEEK * cardStep - CARD_CELL_GAP;
  const qr = encodeQr(url);
  const qrQuietZone = QR_QUIET_ZONE * QR_MODULE;
  const qrCodeSize = qr ? qrTileSize(qr) - qrQuietZone * 2 : 0;
  const qrTop = CONTENT_BOTTOM - qrCodeSize + QR_DROP;
  const total = days.reduce((sum, { count }) => sum + count, 0);
  const tanukiPixels = pixelate(tanuki, QR_TANUKI_MODULES, VIDEO_THEME.tanuki);
  const detailLineHeight = DETAIL_SIZE * SUMMARY_LINE_HEIGHT;
  const displayUrl = url.replace(/^https?:\/\//, '');
  const cardHeaderBottom = bylineTop + AVATAR_SIZE;

  setFont(DETAIL_SIZE);
  const totalCaptionLines = wrapLines(
    context,
    sprintf(
      n__(
        'ContributionMusic|contribution · %{dates}',
        'ContributionMusic|contributions · %{dates}',
        total,
      ),
      { dates },
      false,
    ),
    textWidth,
  );
  const cardUrlBaseline = qrTop - CARD_URL_GAP;
  const cardMiddleBottom = qr ? cardUrlBaseline - DETAIL_SIZE - CARD_TOTAL_GAP : CONTENT_BOTTOM;
  const totalText = formatNumber(total, { useGrouping: false });

  // Scale the total to fill the text width, so short and long numbers both land big.
  setFont(100, CARD_TOTAL_WEIGHT, MONO);
  const totalSize = Math.min(
    CARD_TOTAL_MAX_SIZE,
    (100 * textWidth) / context.measureText(totalText).width,
  );
  setFont(totalSize, CARD_TOTAL_WEIGHT, MONO);
  const totalMetrics = context.measureText(totalText);
  const totalAscent = totalMetrics.actualBoundingBoxAscent;
  const totalDescent = totalMetrics.actualBoundingBoxDescent;
  const cardMiddleHeight =
    totalAscent +
    totalDescent +
    CARD_TOTAL_LABEL_GAP +
    DETAIL_SIZE +
    (totalCaptionLines.length - 1) * detailLineHeight +
    CARD_TOTAL_GAP +
    cardGraphHeight;
  const cardTotalBaseline =
    (cardHeaderBottom + cardMiddleBottom - cardMiddleHeight) / 2 + totalAscent;
  const cardTotalLabelBaseline =
    cardTotalBaseline + totalDescent + CARD_TOTAL_LABEL_GAP + DETAIL_SIZE;
  const cardGraphTop =
    cardTotalLabelBaseline + (totalCaptionLines.length - 1) * detailLineHeight + CARD_TOTAL_GAP;

  const edgeMask = stripContext.createLinearGradient(0, 0, VIDEO_WIDTH, 0);
  edgeMask.addColorStop(0, 'transparent');
  edgeMask.addColorStop(EDGE_FADE_WIDTH / VIDEO_WIDTH, 'black');
  edgeMask.addColorStop(1 - EDGE_FADE_WIDTH / VIDEO_WIDTH, 'black');
  edgeMask.addColorStop(1, 'transparent');

  const fillLines = (lines, { x, y, lineHeight }) => {
    lines.forEach((line, index) => context.fillText(line, x, y + index * lineHeight));
  };

  const drawStrip = ({ position }) => {
    stripContext.globalCompositeOperation = 'source-over';
    stripContext.clearRect(0, 0, VIDEO_WIDTH, stripHeight);

    const left = PLAYHEAD_X - position * graphWidth;

    drawMonthLabels(strip, months, {
      left,
      top: 0,
      step: CELL_SIZE + CELL_GAP,
      fontSize: DETAIL_SIZE,
      fontFamily: MONO,
      fill: VIDEO_THEME.muted,
      opacity: 1,
    });
    drawGrid(strip, grid, {
      left,
      top: monthRowHeight,
      cellSize: CELL_SIZE,
      gap: CELL_GAP,
      radius: CELL_RADIUS,
      drawCellEffect: (cellCanvas, cell) =>
        drawGlow(cellCanvas, { ...cell, color: BRAND_COLORS[cell.level], front: PLAYHEAD_X }),
    });

    stripContext.globalAlpha = 1;
    stripContext.globalCompositeOperation = 'destination-in';
    stripContext.fillStyle = edgeMask;
    stripContext.fillRect(0, 0, VIDEO_WIDTH, stripHeight);

    context.drawImage(strip, 0, stripTop);
  };

  // Avatar with display name over @username, the usual GitLab user lockup.
  const drawByline = () => {
    if (avatar) {
      context.save();
      context.beginPath();
      context.arc(
        PADDING_X + AVATAR_SIZE / 2,
        bylineTop + AVATAR_SIZE / 2,
        AVATAR_SIZE / 2,
        0,
        Math.PI * 2,
      );
      context.clip();
      context.drawImage(avatar, PADDING_X, bylineTop, AVATAR_SIZE, AVATAR_SIZE);
      context.restore();
    }

    context.textAlign = 'left';
    context.textBaseline = 'middle';
    context.fillStyle = VIDEO_THEME.text;
    setFont(NAME_SIZE, 'bold');
    context.fillText(
      displayName,
      bylineTextLeft,
      bylineTop + (name ? AVATAR_SIZE * 0.36 : AVATAR_SIZE / 2),
    );

    if (name) {
      context.fillStyle = VIDEO_THEME.muted;
      setFont(DETAIL_SIZE, 'normal', MONO);
      context.fillText(handle, bylineTextLeft, bylineTop + AVATAR_SIZE * 0.78);
    }
  };

  // Logo, title and byline stay put for the whole video.
  const drawHeader = () => {
    context.globalAlpha = 1;
    context.textAlign = 'left';
    context.textBaseline = 'alphabetic';
    context.drawImage(
      logo,
      logoBox.left,
      logoBox.top,
      logoBox.width,
      logoBox.height,
      PADDING_X,
      LOGO_TOP,
      logoWidth,
      LOGO_HEIGHT,
    );
    context.textBaseline = 'alphabetic';
    context.fillStyle = VIDEO_THEME.muted;
    setFont(DETAIL_SIZE, 'normal', MONO);
    context.fillText('/', PADDING_X + logoWidth + EYEBROW_GAP, eyebrowBaseline);
    context.fillText(
      title,
      PADDING_X + logoWidth + EYEBROW_GAP * 2 + context.measureText('/').width,
      eyebrowBaseline,
    );
    drawByline();
  };

  const drawMessage = () => {
    context.textAlign = 'left';
    context.textBaseline = 'alphabetic';
    context.fillStyle = VIDEO_THEME.text;
    setFont(SUMMARY_SIZE);
    fillLines(summaryLines, { x: PADDING_X, y: summaryY, lineHeight: summaryLineHeight });
  };

  const drawStamp = (opacity) => {
    context.globalAlpha = opacity * STAMP_ALPHA;
    context.textAlign = 'left';
    context.textBaseline = 'alphabetic';
    context.fillStyle = VIDEO_THEME.accent;
    setFont(STAMP_SIZE, 'normal', MONO);
    context.fillText(stamp, PADDING_X, stampBaseline);
    context.globalAlpha = opacity;
  };

  const drawSong = (opacity, { position, spectrum }) => {
    context.globalAlpha = opacity;
    drawMessage();
    drawStrip({ position });
    drawStamp(opacity);

    context.fillStyle = VIDEO_THEME.accent;
    context.fillRect(
      PLAYHEAD_X - PLAYHEAD_WIDTH / 2,
      graphTop - CELL_GAP,
      PLAYHEAD_WIDTH,
      GRAPH_HEIGHT + CELL_GAP * 2,
    );

    context.globalAlpha = opacity * FILL_ALPHA;
    context.fillStyle = VIDEO_THEME.accent;
    drawBars(context, spectrum, {
      centerX: VIDEO_WIDTH / 2,
      centerY: barsCenterY,
      halfWidth: VIDEO_WIDTH / 2 - PADDING_X,
      height: BARS_HEIGHT,
      clearance: BARS_GAP / 2,
      barWidth: BARS_WIDTH,
      barGap: BARS_GAP,
    });
  };

  const countProgress = (elapsed) =>
    Math.min(Math.max((elapsed - TOTAL_COUNT_DELAY_MS) / TOTAL_COUNT_MS, 0), 1);
  // Runs past the chart's right edge by the glow's length, so the glow leaves with it.
  const cardRecolorFront = (elapsed) =>
    PADDING_X +
    easeOutQuad(Math.min(Math.max((elapsed - CARD_RECOLOR_DELAY_MS) / CARD_RECOLOR_MS, 0), 1)) *
      (textWidth + GLOW_COLUMNS * cardStep);

  const drawCard = (opacity, elapsed) => {
    context.globalAlpha = opacity;
    context.textAlign = 'left';
    context.textBaseline = 'alphabetic';
    context.fillStyle = VIDEO_THEME.text;
    setFont(totalSize, CARD_TOTAL_WEIGHT, MONO);
    context.fillText(
      formatNumber(Math.round(total * easeOutQuad(countProgress(elapsed))), {
        useGrouping: false,
      }),
      PADDING_X,
      cardTotalBaseline,
    );
    context.fillStyle = VIDEO_THEME.muted;
    setFont(DETAIL_SIZE);
    fillLines(totalCaptionLines, {
      x: PADDING_X,
      y: cardTotalLabelBaseline,
      lineHeight: detailLineHeight,
    });

    drawGrid(canvas, grid, {
      left: PADDING_X,
      top: cardGraphTop,
      cellSize: cardCellSize,
      gap: CARD_CELL_GAP,
      radius: CARD_CELL_RADIUS,
      opacity,
      drawCellEffect: (cellCanvas, cell) =>
        drawGlow(cellCanvas, {
          ...cell,
          color: BRAND_COLORS[cell.level],
          front: cardRecolorFront(elapsed),
        }),
      // Weeks sweep in left to right once the card has faded in.
      weekOpacity: (weekIndex) =>
        easeOutCubic(
          Math.min(
            Math.max(
              (elapsed - CHART_REVEAL_DELAY_MS - weekIndex * CHART_REVEAL_STAGGER_MS) /
                CHART_REVEAL_MS,
              0,
            ),
            1,
          ),
        ),
    });

    context.globalAlpha = opacity;

    if (qr) {
      context.textAlign = 'center';
      context.textBaseline = 'alphabetic';
      context.fillStyle = VIDEO_THEME.muted;
      setFont(DETAIL_SIZE, 'normal', MONO);
      context.fillText(displayUrl, VIDEO_WIDTH / 2, cardUrlBaseline);
      drawQrTile(canvas, {
        qr,
        tanukiPixels,
        left: (VIDEO_WIDTH - qrCodeSize) / 2 - qrQuietZone,
        top: qrTop - qrQuietZone,
      });
    }
  };

  return ({ endedAt, now, ...frame }) => {
    const progress =
      endedAt === null
        ? 0
        : Math.min(Math.max((now - endedAt - CARD_DELAY_MS) / CARD_FADE_MS, 0), 1);
    const songOpacity = Math.max(1 - progress * 2, 0);
    const cardOpacity = Math.max(progress * 2 - 1, 0);

    context.globalAlpha = 1;
    context.fillStyle = VIDEO_THEME.background;
    context.fillRect(0, 0, VIDEO_WIDTH, VIDEO_HEIGHT);
    context.globalAlpha = WAVE_FAINT_OPACITY;
    context.drawImage(wave, 0, (WAVE_VISIBLE - 1) * VIDEO_HEIGHT);
    context.globalAlpha = 1;
    drawHeader();

    if (songOpacity > 0) {
      drawSong(songOpacity, { now, ...frame });
    }

    if (cardOpacity > 0) {
      drawCard(cardOpacity, now - endedAt);
    }
  };
};

// CORS-enabled loading keeps the canvas origin-clean for avatars on other hosts like Gravatar,
// which CSP allows as images but not as fetch requests. Hosts without CORS just skip the avatar.
const loadAvatar = (url) =>
  new Promise((resolve) => {
    if (!url) {
      resolve(null);
      return;
    }

    const image = new Image();
    image.crossOrigin = 'anonymous';
    image.onload = () => resolve(image);
    image.onerror = () => resolve(null);
    image.src = url;
  });

const prepareDrawer = async ({ avatarUrl, ...options }) => {
  // Canvas text falls back silently if the web fonts haven't been fetched yet.
  await Promise.all([document.fonts.load(`bold 1em ${SANS}`), document.fonts.load(`1em ${MONO}`)]);

  return createFrameDrawer({
    ...options,
    logo: await loadSvg(logoSvg),
    tanuki: await loadSvg(tanukiSvg),
    avatar: await loadAvatar(avatarUrl),
  });
};

// Draws the lockup without the press kit's built-in clear space, so it aligns with text.
export const drawLogo = async (canvas, height) => {
  const logo = await loadSvg(logoSvg);
  const box = contentBox(logo);
  const width = (height * box.width) / box.height;
  const ratio = window.devicePixelRatio || 1;

  /* eslint-disable no-param-reassign */
  canvas.width = width * ratio;
  canvas.height = height * ratio;
  canvas.style.width = `${width}px`;
  canvas.style.height = `${height}px`;
  // Lifts the element's baseline to the wordmark's, for baseline-aligned text beside it.
  canvas.style.marginBottom = `${-(1 - wordmarkBaseline(logo)) * height}px`;
  /* eslint-enable no-param-reassign */
  canvas
    .getContext('2d')
    .drawImage(logo, box.left, box.top, box.width, box.height, 0, 0, canvas.width, canvas.height);
};

// The end card's QR tile on its own, at the display's pixel density.
export const drawQrCode = async (canvas, url) => {
  const qr = encodeQr(url);

  if (!qr) {
    return;
  }

  const tanukiPixels = pixelate(await loadSvg(tanukiSvg), QR_TANUKI_MODULES, VIDEO_THEME.tanuki);
  const size = qrTileSize(qr);
  const ratio = window.devicePixelRatio || 1;

  /* eslint-disable no-param-reassign */
  canvas.width = size * ratio;
  canvas.height = size * ratio;
  /* eslint-enable no-param-reassign */
  canvas.getContext('2d').setTransform(ratio, 0, 0, ratio, 0, 0);
  drawQrTile(canvas, { qr, tanukiPixels, left: 0, top: 0 });
};

// Draws a still of the end card, fully faded in.
export const drawVideoPreview = async (canvas, content) => {
  // eslint-disable-next-line no-param-reassign
  canvas.width = VIDEO_WIDTH;
  // eslint-disable-next-line no-param-reassign
  canvas.height = VIDEO_HEIGHT;

  const draw = await prepareDrawer({ canvas, ...content });

  draw({ endedAt: -Infinity, now: 0 });
};

export const recordVideo = ({ columns, columnsPerSecond, ...content }) =>
  new Promise((resolve, reject) => {
    const mimeType = pickMimeType();
    const canvas = document.createElement('canvas');
    canvas.width = VIDEO_WIDTH;
    canvas.height = VIDEO_HEIGHT;

    const tail = Array.from({ length: Math.ceil(VIDEO_TAIL_SECONDS * columnsPerSecond) }, () => []);
    const runColumns = [...columns, ...tail];

    let draw = null;
    let position = 0;
    let endedAt = null;
    let audioStream = null;
    let recorder = null;
    let frame = null;

    const player = createPlayer({
      connectOutput: (context, node) => {
        const destination = context.createMediaStreamDestination();

        node.connect(destination);
        audioStream = destination.stream;
      },
      onColumn: noop,
      onPosition: (runPosition) => {
        position = Math.max(
          position,
          Math.min((runPosition * runColumns.length) / columns.length, 1),
        );
        if (position === 1 && endedAt === null) {
          endedAt = performance.now();
        }
      },
      onEnd: () => recorder.stop(),
    });

    const render = () => {
      draw({ position, endedAt, now: performance.now(), spectrum: player.readSpectrum() });
      frame = requestAnimationFrame(render);
    };

    const visibility = new AbortController();

    const finish = (error) => {
      visibility.abort();
      cancelAnimationFrame(frame);
      player.destroy();

      return error;
    };

    const onVisibilityChange = () => {
      if (document.hidden) {
        recorder.onstop = null;
        recorder.stop();
        reject(finish(new VideoInterruptedError()));
      }
    };

    const begin = async () => {
      draw = await prepareDrawer({ ...content, canvas });

      await player.start({ columns: runColumns, columnsPerSecond, loop: false });

      const chunks = [];
      const stream = new MediaStream([
        ...canvas.captureStream(VIDEO_FPS).getVideoTracks(),
        ...audioStream.getAudioTracks(),
      ]);

      recorder = new MediaRecorder(stream, { mimeType });
      recorder.ondataavailable = ({ data }) => {
        if (data.size) {
          chunks.push(data);
        }
      };
      recorder.onstop = () => {
        finish();
        resolve({
          blob: new Blob(chunks, { type: mimeType }),
          extension: mimeType.startsWith('video/mp4') ? 'mp4' : 'webm',
        });
      };
      recorder.onerror = ({ error }) => reject(finish(error));

      render();
      recorder.start();

      // Background tabs throttle timers and stop animation frames, which leaves a frozen,
      // out-of-sync video, so give up instead.
      document.addEventListener('visibilitychange', onVisibilityChange, {
        signal: visibility.signal,
      });
      onVisibilityChange();
    };

    begin().catch((error) => reject(finish(error)));
  });

<script>
import {
  PREVIEW_PIECE_STAT,
  PREVIEW_PIECE_BAR_ROWS,
  PREVIEW_PIECE_LINE_CHART,
  PREVIEW_PIECE_TEXT_LINES,
  PREVIEW_PIECE_TYPES,
  buildThumbnailLayout,
} from './dashboard_preview_layout';

// Renders the wireframe thumbnail computed by buildThumbnailLayout; all
// selection and arrangement logic lives in dashboard_preview_layout.js.
export default {
  name: 'DashboardCardThumbnail',
  PREVIEW_PIECE_STAT,
  PREVIEW_PIECE_BAR_ROWS,
  PREVIEW_PIECE_LINE_CHART,
  PREVIEW_PIECE_TEXT_LINES,
  props: {
    seedKey: {
      type: String,
      required: false,
      default: '',
    },
    // Piece descriptors ({ type, wide }) mimicking the dashboard's real
    // panels; when provided they replace the seeded template.
    pieces: {
      type: Array,
      required: false,
      default: null,
      validator: (value) =>
        value === null ||
        value.every(
          (piece) =>
            PREVIEW_PIECE_TYPES.includes(piece?.type) &&
            (piece.wide === undefined || typeof piece.wide === 'boolean'),
        ),
    },
  },
  computed: {
    layout() {
      return buildThumbnailLayout({ seedKey: this.seedKey, pieces: this.pieces });
    },
  },
};
</script>
<template>
  <div
    class="gl-border-b gl-flex gl-h-20 gl-flex-col gl-gap-4 gl-overflow-hidden gl-rounded-t-lg gl-border-subtle gl-bg-default gl-p-4"
    data-testid="dashboard-card-thumbnail"
    aria-hidden="true"
  >
    <div
      v-for="(row, rowIndex) in layout.rows"
      :key="rowIndex"
      class="gl-flex gl-gap-4"
      :class="{ 'gl-min-h-0 gl-grow': row.grow }"
    >
      <div
        v-for="(piece, pieceIndex) in row.pieces"
        :key="pieceIndex"
        class="gl-min-w-0 gl-overflow-hidden gl-rounded-base gl-bg-subtle gl-p-4"
        :class="row.half ? 'gl-w-1/2' : 'gl-flex-1'"
        :data-testid="`dashboard-card-thumbnail-${piece.type}`"
      >
        <div
          v-if="piece.type === $options.PREVIEW_PIECE_STAT"
          class="gl-flex gl-h-full gl-flex-col gl-justify-between gl-gap-2"
        >
          <div class="gl-h-1 gl-rounded-full gl-bg-strong" :class="piece.titleWidth"></div>
          <div class="gl-h-2 gl-w-1/4 gl-rounded-full" :class="layout.accent.bar"></div>
        </div>
        <div
          v-else-if="piece.type === $options.PREVIEW_PIECE_BAR_ROWS"
          class="gl-flex gl-h-full gl-flex-col gl-justify-evenly gl-gap-2"
        >
          <div
            v-for="(bar, barIndex) in piece.bars"
            :key="barIndex"
            class="gl-h-2 gl-rounded-full"
            :class="[bar.width, bar.colored ? layout.accent.bar : 'gl-bg-strong']"
          ></div>
        </div>
        <div
          v-else-if="piece.type === $options.PREVIEW_PIECE_TEXT_LINES"
          class="gl-flex gl-h-full gl-flex-col gl-justify-evenly gl-gap-2"
        >
          <div
            v-for="(lineWidth, lineIndex) in piece.lines"
            :key="lineIndex"
            class="gl-h-1 gl-rounded-full gl-bg-strong"
            :class="lineWidth"
          ></div>
        </div>
        <svg
          v-else-if="piece.type === $options.PREVIEW_PIECE_LINE_CHART"
          class="gl-h-full gl-w-full"
          :class="layout.accent.stroke"
          viewBox="0 0 100 48"
          preserveAspectRatio="none"
          role="presentation"
          focusable="false"
        >
          <path :d="piece.areaPath" fill="currentColor" fill-opacity="0.1" />
          <path
            :d="piece.linePath"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            vector-effect="non-scaling-stroke"
          />
        </svg>
      </div>
    </div>
  </div>
</template>

import { s__, sprintf } from '~/locale';

// See https://design.gitlab.com/data-visualization/color/#categorical-data
const SPAN_COLOR_WEIGHT = ['500', '600', '700', '800', '900', '950'];
const SPAN_COLOR_PALETTE = ['blue', 'orange', 'aqua', 'green', 'magenta'];

export function durationNanoToMs(durationNano) {
  return Math.round(durationNano / 1000);
}

export function formatDurationMs(durationMs) {
  return sprintf(s__('Tracing|%{ms} ms'), { ms: durationMs });
}

export function formatTraceDuration(durationNano) {
  return formatDurationMs(durationNanoToMs(durationNano));
}

function createPalette() {
  const palette = [];
  SPAN_COLOR_WEIGHT.forEach((w) => {
    SPAN_COLOR_PALETTE.forEach((c) => {
      palette.push(`${c}-${w}`);
    });
  });
  return palette;
}

export function assignColorToServices(trace) {
  const services = Array.from(new Set(trace.spans.map((s) => s.service_name)));

  const palette = createPalette();

  const serviceToColor = {};
  services.forEach((s, i) => {
    serviceToColor[s] = palette[i % palette.length];
  });

  return serviceToColor;
}

const timestampToMs = (ts) => new Date(ts).getTime();

export function mapTraceToTreeRoot(trace) {
  const nodes = {};
  let root;

  trace.spans.forEach((s) => {
    const node = {
      startTimeMs:
        root !== undefined ? timestampToMs(s.timestamp) - timestampToMs(root.timestamp) : 0,
      timestamp: s.timestamp,
      spanId: s.span_id,
      operation: s.operation,
      service: s.service_name,
      durationMs: durationNanoToMs(s.duration_nano),
      children: [],
    };
    nodes[s.span_id] = node;

    const parentId = s.parent_span_id;
    if (parentId === '') {
      root = node;
    } else if (nodes[parentId]) {
      nodes[parentId].children.push(node);
    }
  });

  return root;
}

import { GL_COLOR_DATA_BLUE_500, GL_COLOR_ORANGE_400 } from '@gitlab/ui/src/tokens/build/js/tokens';

// Display options and their defaults, shared with the GLQL bar list presenter, which maps
// its `displayConfig` onto the chart props.

// Formats for the label past the end of each bar.
export const VALUE_LABELS_SHARE_AND_VALUE = 'shareAndValue';
export const VALUE_LABELS_VALUE = 'value';
export const VALUE_LABELS_OPTIONS = [VALUE_LABELS_SHARE_AND_VALUE, VALUE_LABELS_VALUE];
export const VALUE_LABELS_DEFAULT = VALUE_LABELS_SHARE_AND_VALUE;

// Bar colours by name. Orange is the design's default; blue is the chart palette's first
// colour, so a blue bar list matches the other GLQL charts' first series.
export const BAR_COLOR_ORANGE = 'orange';
export const BAR_COLOR_BLUE = 'blue';
export const BAR_COLOR_OPTIONS = [BAR_COLOR_ORANGE, BAR_COLOR_BLUE];
export const BAR_COLOR_DEFAULT = BAR_COLOR_ORANGE;
export const BAR_COLOR_TOKENS = {
  [BAR_COLOR_ORANGE]: GL_COLOR_ORANGE_400,
  [BAR_COLOR_BLUE]: GL_COLOR_DATA_BLUE_500,
};

// What a bar's length is measured against. `total` reads as share of the whole; `max` sizes
// every bar against the largest row, which fills the track. `log` plots the values on a log
// axis, so a spread of several orders of magnitude compresses into decades.
export const SCALE_TOTAL = 'total';
export const SCALE_MAX = 'max';
export const SCALE_LOG = 'log';
export const SCALE_OPTIONS = [SCALE_TOTAL, SCALE_MAX, SCALE_LOG];
export const SCALE_DEFAULT = SCALE_TOTAL;

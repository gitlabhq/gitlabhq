import { s__ } from '~/locale';

export const TIMEFRAME_LENGTH = 6;

export const EPIC_DETAILS_CELL_WIDTH = 320;

export const EPIC_ITEM_HEIGHT = 50;

export const TIMELINE_CELL_MIN_WIDTH = 180;

export const SHELL_MIN_WIDTH = 1620;

export const SCROLL_BAR_SIZE = 15;

export const TIMELINE_END_OFFSET_HALF = 8;

export const TIMELINE_END_OFFSET_FULL = 16;

export const PRESET_TYPES = {
  QUARTERS: 'QUARTERS',
  MONTHS: 'MONTHS',
  WEEKS: 'WEEKS',
};

export const PRESET_DEFAULTS = {
  QUARTERS: {
    TIMEFRAME_LENGTH: 18,
    emptyStateDefault: s__('GroupRoadmap|To view the roadmap, add a planned start or finish date to one of your epics in this group or its subgroups. In the quarters view, only epics in the past quarter, current quarter, and next 4 quarters are shown &ndash; from %{startDate} to %{endDate}.'),
    emptyStateWithFilters: s__('GroupRoadmap|To widen your search, change or remove filters. In the quarters view, only epics in the past quarter, current quarter, and next 4 quarters are shown &ndash; from %{startDate} to %{endDate}.'),
  },
  MONTHS: {
    TIMEFRAME_LENGTH: 7,
    emptyStateDefault: s__('GroupRoadmap|To view the roadmap, add a planned start or finish date to one of your epics in this group or its subgroups. In the months view, only epics in the past month, current month, and next 5 months are shown &ndash; from %{startDate} to %{endDate}.'),
    emptyStateWithFilters: s__('GroupRoadmap|To widen your search, change or remove filters. In the months view, only epics in the past month, current month, and next 5 months are shown &ndash; from %{startDate} to %{endDate}.'),
  },
  WEEKS: {
    TIMEFRAME_LENGTH: 42,
    emptyStateDefault: s__('GroupRoadmap|To view the roadmap, add a planned start or finish date to one of your epics in this group or its subgroups. In the weeks view, only epics in the past week, current week, and next 4 weeks are shown &ndash; from %{startDate} to %{endDate}.'),
    emptyStateWithFilters: s__('GroupRoadmap|To widen your search, change or remove filters. In the weeks view, only epics in the past week, current week, and next 4 weeks are shown &ndash; from %{startDate} to %{endDate}.'),
  },
};

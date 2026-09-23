<script>
import { GlButton, GlIcon, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';
import {
  PANEL_STATE_ERROR,
  PANEL_STATE_ERROR_NO_RETRY,
  PANEL_STATE_NO_ACCESS,
  PANEL_STATE_NO_DATA,
  PANEL_STATE_NOT_CONFIGURED,
  PANEL_STATE_UNAVAILABLE,
} from '../constants';

const CLICKHOUSE_DOCS_PATH = helpPagePath('integration/clickhouse');

// Default copy per variant, following the Pajamas empty-state pattern. The non-retryable
// error carries no action on purpose: offering a retry that must fail again is worse
// than offering nothing.
const STATES = {
  [PANEL_STATE_NO_DATA]: {
    title: s__('Analytics|No data yet'),
    description: s__('Analytics|Nothing to show for this scope and period.'),
  },
  [PANEL_STATE_NO_ACCESS]: {
    title: s__("Analytics|You don't have access"),
    description: s__(
      "Analytics|You don't have permission to view this data. Ask an owner for access.",
    ),
  },
  [PANEL_STATE_NOT_CONFIGURED]: {
    title: s__('Analytics|Configuration required'),
    description: s__('Analytics|ClickHouse must be configured before this data is available.'),
    link: CLICKHOUSE_DOCS_PATH,
  },
  [PANEL_STATE_UNAVAILABLE]: {
    title: s__("Analytics|Data isn't available yet"),
    description: s__("Analytics|This data isn't being collected for this scope yet."),
    link: CLICKHOUSE_DOCS_PATH,
  },
  [PANEL_STATE_ERROR]: {
    title: __('Something went wrong'),
    description: s__("Analytics|We couldn't load this data. Try again."),
    icon: 'error',
    retry: true,
  },
  [PANEL_STATE_ERROR_NO_RETRY]: {
    title: __('Something went wrong'),
    description: s__("Analytics|We couldn't load this data. Please try again later."),
    icon: 'error',
  },
};

export default {
  name: 'AnalyticsPanelState',
  components: {
    GlButton,
    GlIcon,
    GlLink,
  },
  props: {
    variant: {
      type: String,
      required: true,
      validator: (variant) => Boolean(STATES[variant]),
    },
    // Compact fits stat-sized panels where a centered block would not.
    compact: {
      type: Boolean,
      required: false,
      default: false,
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['retry'],
  computed: {
    state() {
      return STATES[this.variant];
    },
    stateTitle() {
      return this.title || this.state.title;
    },
    stateDescription() {
      return this.description || this.state.description;
    },
    // Compact fits stat-sized tiles: left-aligned with a heading small enough that the
    // title and description both stay visible in a three-column panel.
    containerClasses() {
      return this.compact
        ? 'gl-flex gl-grow gl-flex-col'
        : 'gl-flex gl-h-full gl-grow gl-flex-col gl-items-center gl-justify-center gl-p-5 gl-text-center';
    },
    titleClasses() {
      return this.compact
        ? 'gl-block gl-text-lg gl-font-bold'
        : 'gl-block gl-text-size-h-display gl-font-semibold gl-leading-36';
    },
    descriptionClasses() {
      return this.compact
        ? 'gl-mb-0 gl-mt-2 gl-text-subtle'
        : 'gl-mb-0 gl-mt-4 gl-text-lg gl-text-subtle';
    },
    // A stat-sized tile cannot fit the description and the retry button; the button says
    // what the description would ("Try again"), so it wins.
    showDescription() {
      return !(this.compact && this.state.retry);
    },
  },
};
</script>

<template>
  <div :class="containerClasses" :data-testid="`panel-state-${variant}`">
    <gl-icon
      v-if="state.icon && !compact"
      :name="state.icon"
      variant="danger"
      :size="16"
      class="gl-mb-4"
    />
    <!-- Deliberately not a heading: GlDashboardPanel titles are not headings, and several
         failing panels would flood the page outline with identical entries. -->
    <strong :class="titleClasses">
      <gl-icon
        v-if="state.icon && compact"
        :name="state.icon"
        variant="danger"
        :size="16"
        class="gl-mr-2"
      />{{ stateTitle }}
    </strong>
    <p v-if="showDescription" :class="descriptionClasses">{{ stateDescription }}</p>
    <gl-button
      v-if="state.retry"
      category="primary"
      variant="confirm"
      :size="compact ? 'small' : 'medium'"
      :class="compact ? 'gl-mt-3 gl-self-start' : 'gl-mt-5 gl-self-center'"
      data-testid="panel-state-retry"
      @click="$emit('retry')"
    >
      {{ __('Try again') }}
    </gl-button>
    <gl-link v-else-if="state.link" :href="state.link" :class="compact ? 'gl-mt-2' : 'gl-mt-5'">
      {{ __('Learn more') }}
    </gl-link>
  </div>
</template>

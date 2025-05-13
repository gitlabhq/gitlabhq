<script>
import { GlFormCheckboxGroup, GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import { parseBoolean } from '~/lib/utils/common_utils';
import {
  EVENT_CLICK_ZOEKT_INCLUDE_FORKS_ON_SEARCH_RESULTS_PAGE,
  EXCLUDE_FORKS_FILTER_PARAM,
} from '~/search/sidebar/constants';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'ForksFilter',
  components: {
    GlFormCheckboxGroup,
    GlFormCheckbox,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [trackingMixin],
  i18n: {
    TOOLTIP: s__('GlobalSearch|Exclude search results from forked projects'),
    HEADER_LABEL: s__('GlobalSearch|Forks'),
    CHECKBOX_LABEL: s__('GlobalSearch|Exclude forks'),
  },
  computed: {
    ...mapState(['urlQuery']),
    selectedFilter: {
      get() {
        return [parseBoolean(this.urlQuery?.[EXCLUDE_FORKS_FILTER_PARAM])];
      },
      set(value) {
        const excludeForks = [...value].pop() ?? false;
        this.setQuery({
          key: EXCLUDE_FORKS_FILTER_PARAM,
          value: excludeForks?.toString(),
        });
      },
    },
  },
  methods: {
    ...mapActions(['setQuery']),
    trackChange() {
      this.trackEvent(EVENT_CLICK_ZOEKT_INCLUDE_FORKS_ON_SEARCH_RESULTS_PAGE);
    },
  },
};
</script>

<template>
  <gl-form-checkbox-group v-model="selectedFilter" @change="trackChange">
    <div class="gl-mb-2 gl-text-sm gl-font-bold" data-testid="archived-filter-title">
      {{ $options.i18n.HEADER_LABEL }}
    </div>
    <gl-form-checkbox class="gl-inline-flex gl-w-full gl-grow gl-justify-between" :value="true">
      <span v-gl-tooltip="$options.i18n.TOOLTIP" data-testid="tooltip-checkbox-label">
        {{ $options.i18n.CHECKBOX_LABEL }}
      </span>
    </gl-form-checkbox>
  </gl-form-checkbox-group>
</template>

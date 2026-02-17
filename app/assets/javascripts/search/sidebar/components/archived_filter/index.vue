<script>
import { GlFormCheckboxGroup, GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { parseBoolean } from '~/lib/utils/common_utils';
import {
  ARCHIVED_TRACKING_NAMESPACE,
  ARCHIVED_TRACKING_LABEL_CHECKBOX,
  ARCHIVED_TRACKING_LABEL_CHECKBOX_LABEL,
  LABEL_DEFAULT_CLASSES,
  INCLUDE_ARCHIVED_FILTER_PARAM,
} from '../../constants';

export default {
  name: 'ArchivedFilter',
  components: {
    GlFormCheckboxGroup,
    GlFormCheckbox,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    tooltip: s__('GlobalSearch|Include search results from archived projects'),
    headerLabel: s__('GlobalSearch|Archived'),
    checkboxLabel: s__('GlobalSearch|Include archived'),
  },
  computed: {
    ...mapState(['urlQuery']),
    selectedFilter: {
      get() {
        return [parseBoolean(this.urlQuery?.[INCLUDE_ARCHIVED_FILTER_PARAM])];
      },
      set(value) {
        const includeArchived = [...value].pop() ?? false;
        this.setQuery({
          key: INCLUDE_ARCHIVED_FILTER_PARAM,
          value: includeArchived?.toString(),
        });
        this.trackSelectCheckbox(includeArchived);
      },
    },
  },
  methods: {
    ...mapActions(['setQuery']),
    trackSelectCheckbox(value) {
      Tracking.event(ARCHIVED_TRACKING_NAMESPACE, ARCHIVED_TRACKING_LABEL_CHECKBOX, {
        label: ARCHIVED_TRACKING_LABEL_CHECKBOX_LABEL,
        property: value,
      });
    },
  },
  LABEL_DEFAULT_CLASSES,
};
</script>

<template>
  <gl-form-checkbox-group v-model="selectedFilter">
    <div class="gl-mb-2 gl-text-sm gl-font-bold" data-testid="archived-filter-title">
      {{ $options.i18n.headerLabel }}
    </div>
    <gl-form-checkbox
      class="gl-inline-flex gl-w-full gl-grow gl-justify-between"
      :class="$options.LABEL_DEFAULT_CLASSES"
      :value="true"
    >
      <span v-gl-tooltip="$options.i18n.tooltip" data-testid="label">
        {{ $options.i18n.checkboxLabel }}
      </span>
    </gl-form-checkbox>
  </gl-form-checkbox-group>
</template>

<script>
import { GlFormCheckboxGroup, GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { parseBoolean } from '~/lib/utils/common_utils';

import { archivedFilterData, TRACKING_NAMESPACE, TRACKING_LABEL_CHECKBOX } from './data';

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
  },
  computed: {
    ...mapState(['urlQuery']),
    selectedFilter: {
      get() {
        return [parseBoolean(this.urlQuery?.include_archived)];
      },
      set(value) {
        const includeArchived = [...value].pop() ?? false;
        this.setQuery({ key: archivedFilterData.filterParam, value: includeArchived?.toString() });
        this.trackSelectCheckbox(includeArchived);
      },
    },
  },
  methods: {
    ...mapActions(['setQuery']),
    trackSelectCheckbox(value) {
      Tracking.event(TRACKING_NAMESPACE, TRACKING_LABEL_CHECKBOX, {
        label: archivedFilterData.checkboxLabel,
        property: value,
      });
    },
  },
  archivedFilterData,
};
</script>

<template>
  <gl-form-checkbox-group v-model="selectedFilter">
    <div class="gl-mb-2 gl-font-weight-bold gl-font-sm" data-testid="archived-filter-title">
      {{ $options.archivedFilterData.headerLabel }}
    </div>
    <gl-form-checkbox
      class="gl-flex-grow-1 gl-display-inline-flex gl-justify-content-space-between gl-w-full"
      :class="$options.LABEL_DEFAULT_CLASSES"
      :value="true"
    >
      <span v-gl-tooltip="$options.i18n.tooltip" data-testid="label">
        {{ $options.archivedFilterData.checkboxLabel }}
      </span>
    </gl-form-checkbox>
  </gl-form-checkbox-group>
</template>

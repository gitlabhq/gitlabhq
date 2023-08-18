<script>
import { GlFormCheckboxGroup, GlFormCheckbox } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import Tracking from '~/tracking';
import { parseBoolean } from '~/lib/utils/common_utils';

import { archivedFilterData, TRACKING_NAMESPACE, TRACKING_LABEL_CHECKBOX } from './data';

export default {
  name: 'ArchivedFilter',
  components: {
    GlFormCheckboxGroup,
    GlFormCheckbox,
  },
  computed: {
    ...mapState(['urlQuery']),
    selectedFilter: {
      get() {
        return [parseBoolean(this.urlQuery?.include_archived)];
      },
      set(value) {
        const newValue = value?.pop() ?? false;
        this.setQuery({ key: archivedFilterData.filterParam, value: newValue?.toString() });
        this.trackSelectCheckbox(newValue);
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
    <h5>{{ $options.archivedFilterData.headerLabel }}</h5>
    <gl-form-checkbox
      class="gl-flex-grow-1 gl-display-inline-flex gl-justify-content-space-between gl-w-full"
      :class="$options.LABEL_DEFAULT_CLASSES"
      :value="true"
    >
      <span data-testid="label">
        {{ $options.archivedFilterData.checkboxLabel }}
      </span>
    </gl-form-checkbox>
  </gl-form-checkbox-group>
</template>

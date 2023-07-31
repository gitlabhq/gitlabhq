<script>
import { GlFormCheckboxGroup, GlFormCheckbox } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import Tracking from '~/tracking';

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
        return [Boolean(this.urlQuery?.include_archived)];
      },
      set([value = '']) {
        this.setQuery({ key: archivedFilterData.filterParam, value: `${value}` });
        this.trackSelectCheckbox(value);
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

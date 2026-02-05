<script>
import { GlFormCheckboxGroup, GlFormCheckbox } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters } from 'vuex';
import { intersection } from 'lodash';
import Tracking from '~/tracking';
import { NAV_LINK_COUNT_DEFAULT_CLASSES, LABEL_DEFAULT_CLASSES } from '../../constants';
import { formatSearchResultCount } from '../../../store/utils';
import { TRACKING_LABEL_SET, TRACKING_LABEL_CHECKBOX } from './tracking';

export default {
  name: 'CheckboxFilter',
  components: {
    GlFormCheckboxGroup,
    GlFormCheckbox,
  },
  props: {
    filtersData: {
      type: Object,
      required: true,
    },
    trackingNamespace: {
      type: String,
      required: true,
    },
    queryParam: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['queryLanguageFilters']),
    dataFilters() {
      return Object.values(this.filtersData?.filters || []);
    },
    flatDataFilterValues() {
      return this.dataFilters.map(({ value }) => value);
    },
    selectedFilter: {
      get() {
        return intersection(this.flatDataFilterValues, this.queryLanguageFilters);
      },
      async set(value) {
        this.setQuery({ key: this.queryParam, value });

        this.$nextTick(() => {
          this.trackSelectCheckbox();
        });
      },
    },
    labelCountClasses() {
      return [...NAV_LINK_COUNT_DEFAULT_CLASSES, 'gl-text-subtle', 'gl-ml-2', 'gl-flex-shrink-0'];
    },
  },
  methods: {
    ...mapActions(['setQuery']),
    getFormattedCount(count) {
      return formatSearchResultCount(count);
    },
    trackSelectCheckbox() {
      Tracking.event(this.trackingNamespace, TRACKING_LABEL_CHECKBOX, {
        label: TRACKING_LABEL_SET,
        property: this.selectedFilter,
      });
    },
  },
  LABEL_DEFAULT_CLASSES,
};
</script>

<template>
  <gl-form-checkbox-group v-model="selectedFilter" class="gl-min-w-0">
    <gl-form-checkbox
      v-for="f in dataFilters"
      :key="f.label"
      :value="f.label"
      :class="$options.LABEL_DEFAULT_CLASSES"
    >
      <span class="gl-flex gl-w-full gl-min-w-0 gl-items-center gl-justify-between">
        <span class="gl-truncate" data-testid="label" :title="f.label">{{ f.label }}</span>
        <span v-if="f.count" :class="labelCountClasses" data-testid="labelCount">
          {{ getFormattedCount(f.count) }}
        </span>
      </span>
    </gl-form-checkbox>
  </gl-form-checkbox-group>
</template>

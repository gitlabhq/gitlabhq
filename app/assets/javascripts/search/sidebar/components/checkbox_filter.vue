<script>
import { GlFormCheckboxGroup, GlFormCheckbox } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { intersection } from 'lodash';
import { NAV_LINK_COUNT_DEFAULT_CLASSES, LABEL_DEFAULT_CLASSES } from '../constants';
import { formatSearchResultCount } from '../../store/utils';

export default {
  name: 'CheckboxFilter',
  components: {
    GlFormCheckboxGroup,
    GlFormCheckbox,
  },
  props: {
    filterData: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['query']),
    scope() {
      return this.query.scope;
    },
    queryFilters() {
      return this.query[this.filterData?.filterParam] || [];
    },
    dataFilters() {
      return Object.values(this.filterData?.filters || []);
    },
    flatDataFilterValues() {
      return this.dataFilters.map(({ value }) => value);
    },
    selectedFilter: {
      get() {
        return intersection(this.flatDataFilterValues, this.queryFilters);
      },
      set(value) {
        this.setQuery({ key: this.filterData?.filterParam, value });
      },
    },
    labelCountClasses() {
      return [...NAV_LINK_COUNT_DEFAULT_CLASSES, 'gl-text-gray-500'];
    },
  },
  methods: {
    ...mapActions(['setQuery']),
    getFormatedCount(count) {
      return formatSearchResultCount(count);
    },
  },
  NAV_LINK_COUNT_DEFAULT_CLASSES,
  LABEL_DEFAULT_CLASSES,
};
</script>

<template>
  <div class="gl-mx-5">
    <h5 class="gl-mt-0">{{ filterData.header }}</h5>
    <gl-form-checkbox-group v-model="selectedFilter">
      <gl-form-checkbox
        v-for="f in dataFilters"
        :key="f.label"
        :value="f.label"
        class="gl-flex-grow-1 gl-display-inline-flex gl-justify-content-space-between gl-w-full"
        :class="$options.LABEL_DEFAULT_CLASSES"
      >
        <span
          class="gl-flex-grow-1 gl-display-inline-flex gl-justify-content-space-between gl-w-full"
        >
          <span data-testid="label">
            {{ f.label }}
          </span>
          <span v-if="f.count" :class="labelCountClasses" data-testid="labelCount">
            {{ getFormatedCount(f.count) }}
          </span>
        </span>
      </gl-form-checkbox>
    </gl-form-checkbox-group>
  </div>
</template>

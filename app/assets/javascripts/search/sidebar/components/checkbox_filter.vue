<script>
import Vue from 'vue';
import { GlFormCheckboxGroup, GlFormCheckbox } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { intersection } from 'lodash';
import Tracking from '~/tracking';
import { NAV_LINK_COUNT_DEFAULT_CLASSES, LABEL_DEFAULT_CLASSES } from '../constants';
import { formatSearchResultCount } from '../../store/utils';

export const TRACKING_LABEL_SET = 'set';
export const TRACKING_LABEL_CHECKBOX = 'checkbox';

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
  },
  computed: {
    ...mapState(['query', 'useNewNavigation']),
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
        this.setQuery({ key: this.filtersData?.filterParam, value });

        await Vue.nextTick();
        this.trackSelectCheckbox();
      },
    },
    labelCountClasses() {
      return [...NAV_LINK_COUNT_DEFAULT_CLASSES, 'gl-text-gray-500'];
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
  NAV_LINK_COUNT_DEFAULT_CLASSES,
  LABEL_DEFAULT_CLASSES,
};
</script>

<template>
  <div class="gl-mx-5">
    <h5 class="gl-mt-0" :class="{ 'gl-font-sm': useNewNavigation }">{{ filtersData.header }}</h5>
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
            {{ getFormattedCount(f.count) }}
          </span>
        </span>
      </gl-form-checkbox>
    </gl-form-checkbox-group>
  </div>
</template>

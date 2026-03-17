<script>
import { GlFormCheckboxGroup, GlFormCheckbox } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters } from 'vuex';
import {
  WORK_ITEM_TYPE_FILTER_PARAM,
  WORK_ITEM_TYPE_FILTER_HEADER,
  NAV_LINK_COUNT_DEFAULT_CLASSES,
  LABEL_DEFAULT_CLASSES,
} from '~/search/sidebar/constants';
import { formatSearchResultCount } from '~/search/store/utils';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';

export default {
  name: 'TypeFilter',
  components: {
    GlFormCheckboxGroup,
    GlFormCheckbox,
    WorkItemTypeIcon,
  },
  i18n: {
    header: WORK_ITEM_TYPE_FILTER_HEADER,
  },
  data() {
    return {
      selectedTypes: [],
    };
  },
  computed: {
    ...mapGetters(['queryWorkItemTypeFilters', 'workItemTypes', 'workItemTypeAggregationBuckets']),
    bucketsByType() {
      const map = {};
      for (const bucket of this.workItemTypeAggregationBuckets) {
        map[bucket.base_type] = bucket;
      }
      return map;
    },
    displayedTypes() {
      const buckets = this.workItemTypeAggregationBuckets;
      if (buckets.length === 0) {
        return this.workItemTypes;
      }
      return this.workItemTypes
        .filter((type) => type.name in this.bucketsByType)
        .sort((a, b) => {
          const countA = this.bucketsByType[a.name]?.count || 0;
          const countB = this.bucketsByType[b.name]?.count || 0;
          return countB - countA;
        });
    },
    selectedTypesModel: {
      get() {
        return this.selectedTypes;
      },
      set(value) {
        this.selectedTypes = value;
        this.updateFilter();
      },
    },
  },
  created() {
    this.selectedTypes = this.queryWorkItemTypeFilters;
    this.fetchAllAggregation();
  },
  methods: {
    ...mapActions(['setQuery', 'fetchAllAggregation']),
    updateFilter() {
      this.setQuery({ key: WORK_ITEM_TYPE_FILTER_PARAM, value: this.selectedTypes });
    },
    getFormattedCount(typeName) {
      const count = this.bucketsByType[typeName]?.count;
      return count != null ? formatSearchResultCount(count) : null;
    },
  },
  WORK_ITEM_TYPE_FILTER_PARAM,
  LABEL_DEFAULT_CLASSES,
  labelCountClasses: [
    ...NAV_LINK_COUNT_DEFAULT_CLASSES,
    'gl-text-subtle',
    'gl-ml-2',
    'gl-flex-shrink-0',
  ],
};
</script>

<template>
  <div class="type-filter-checkbox">
    <div class="gl-mb-2 gl-text-sm gl-font-bold">
      {{ $options.i18n.header }}
    </div>
    <gl-form-checkbox-group v-model="selectedTypesModel" class="gl-min-w-0">
      <gl-form-checkbox
        v-for="type in displayedTypes"
        :key="type.name"
        :value="type.name"
        :class="$options.LABEL_DEFAULT_CLASSES"
      >
        <span class="gl-flex gl-w-full gl-min-w-0 gl-items-center gl-justify-between">
          <span class="gl-inline-flex gl-items-center gl-gap-2 gl-truncate">
            <work-item-type-icon :work-item-type="type.name" :type-icon-name="type.icon_name" />
            <span data-testid="label" :title="type.label">
              {{ type.label }}
            </span>
          </span>
          <span
            v-if="getFormattedCount(type.name)"
            :class="$options.labelCountClasses"
            data-testid="labelCount"
          >
            {{ getFormattedCount(type.name) }}
          </span>
        </span>
      </gl-form-checkbox>
    </gl-form-checkbox-group>
  </div>
</template>

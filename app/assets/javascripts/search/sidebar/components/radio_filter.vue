<script>
import { GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions, mapGetters } from 'vuex';
import { sprintf, __ } from '~/locale';

export default {
  name: 'RadioFilter',
  components: {
    GlFormRadioGroup,
    GlFormRadio,
  },
  props: {
    filterData: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['query']),
    ...mapGetters(['currentScope']),
    ANY() {
      return this.filterData.filters.ANY;
    },
    initialFilter() {
      return this.query[this.filterData.filterParam];
    },
    filter() {
      return this.initialFilter || this.ANY.value;
    },
    filtersArray() {
      return this.filterData.filterByScope[this.currentScope];
    },
    selectedFilter: {
      get() {
        if (this.filtersArray.some(({ value }) => value === this.filter)) {
          return this.filter;
        }

        return this.ANY.value;
      },
      set(value) {
        this.setQuery({ key: this.filterData.filterParam, value });
      },
    },
  },
  methods: {
    ...mapActions(['setQuery']),
    radioLabel(filter) {
      return filter.value === this.ANY.value
        ? sprintf(__('Any %{header}'), { header: this.filterData.header.toLowerCase() })
        : filter.label;
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-mb-2 gl-font-bold gl-font-sm">
      {{ filterData.header }}
    </div>
    <gl-form-radio-group v-model="selectedFilter">
      <gl-form-radio v-for="f in filtersArray" :key="f.value" :value="f.value">
        {{ radioLabel(f) }}
      </gl-form-radio>
    </gl-form-radio-group>
  </div>
</template>

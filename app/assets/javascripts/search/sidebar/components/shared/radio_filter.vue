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
    filtersArray: {
      type: Object,
      required: true,
    },
    header: {
      type: String,
      required: true,
    },
    filterParam: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['query']),
    ...mapGetters(['currentScope']),
    ANY() {
      const AnyIndex = this.filtersArray[this.currentScope].findIndex(
        (item) => item.value === null,
      );
      return this.filtersArray[this.currentScope][AnyIndex];
    },
    initialFilter() {
      return this.query[this.filterParam];
    },
    filter() {
      return this.initialFilter || this.ANY.value;
    },
    selectedFilter: {
      get() {
        if (this.filtersArray[this.currentScope].some(({ value }) => value === this.filter)) {
          return this.filter;
        }

        return this.ANY.value;
      },
      set(value) {
        this.setQuery({ key: this.filterParam, value });
      },
    },
  },
  methods: {
    ...mapActions(['setQuery']),
    radioLabel(filter) {
      return filter.value === this.ANY.value
        ? sprintf(__('Any %{header}'), { header: this.header.toLowerCase() })
        : filter.label;
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-mb-2 gl-text-sm gl-font-bold">
      {{ header }}
    </div>
    <gl-form-radio-group v-model="selectedFilter">
      <gl-form-radio v-for="f in filtersArray[currentScope]" :key="f.value" :value="f.value">
        {{ radioLabel(f) }}
      </gl-form-radio>
    </gl-form-radio-group>
  </div>
</template>

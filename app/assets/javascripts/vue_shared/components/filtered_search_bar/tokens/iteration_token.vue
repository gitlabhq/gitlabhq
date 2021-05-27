<script>
import {
  GlDropdownDivider,
  GlFilteredSearchSuggestion,
  GlFilteredSearchToken,
  GlLoadingIcon,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import createFlash from '~/flash';
import { __ } from '~/locale';
import { DEBOUNCE_DELAY, DEFAULT_ITERATIONS } from '../constants';

export default {
  components: {
    GlDropdownDivider,
    GlFilteredSearchSuggestion,
    GlFilteredSearchToken,
    GlLoadingIcon,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      iterations: this.config.initialIterations || [],
      defaultIterations: this.config.defaultIterations || DEFAULT_ITERATIONS,
      loading: true,
    };
  },
  computed: {
    currentValue() {
      return this.value.data;
    },
    activeIteration() {
      return this.iterations.find((iteration) => iteration.title === this.currentValue);
    },
  },
  watch: {
    active: {
      immediate: true,
      handler(newValue) {
        if (!newValue && !this.iterations.length) {
          this.fetchIterationBySearchTerm(this.currentValue);
        }
      },
    },
  },
  methods: {
    fetchIterationBySearchTerm(searchTerm) {
      const fetchPromise = this.config.fetchPath
        ? this.config.fetchIterations(this.config.fetchPath, searchTerm)
        : this.config.fetchIterations(searchTerm);

      this.loading = true;

      fetchPromise
        .then((response) => {
          this.iterations = Array.isArray(response) ? response : response.data;
        })
        .catch(() => createFlash({ message: __('There was a problem fetching iterations.') }))
        .finally(() => {
          this.loading = false;
        });
    },
    searchIterations: debounce(function debouncedSearch({ data }) {
      this.fetchIterationBySearchTerm(data);
    }, DEBOUNCE_DELAY),
  },
};
</script>

<template>
  <gl-filtered-search-token
    :config="config"
    v-bind="{ ...$props, ...$attrs }"
    v-on="$listeners"
    @input="searchIterations"
  >
    <template #view="{ inputValue }">
      {{ activeIteration ? activeIteration.title : inputValue }}
    </template>
    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="iteration in defaultIterations"
        :key="iteration.value"
        :value="iteration.value"
      >
        {{ iteration.text }}
      </gl-filtered-search-suggestion>
      <gl-dropdown-divider v-if="defaultIterations.length" />
      <gl-loading-icon v-if="loading" />
      <template v-else>
        <gl-filtered-search-suggestion
          v-for="iteration in iterations"
          :key="iteration.title"
          :value="iteration.title"
        >
          {{ iteration.title }}
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </gl-filtered-search-token>
</template>

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
import { DEBOUNCE_DELAY, DEFAULT_NONE_ANY } from '../constants';

export default {
  components: {
    GlDropdownDivider,
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
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
      epics: this.config.initialEpics || [],
      loading: true,
    };
  },
  computed: {
    currentValue() {
      return Number(this.value.data);
    },
    defaultEpics() {
      return this.config.defaultEpics || DEFAULT_NONE_ANY;
    },
    idProperty() {
      return this.config.idProperty || 'id';
    },
    activeEpic() {
      return this.epics.find((epic) => epic[this.idProperty] === this.currentValue);
    },
  },
  watch: {
    active: {
      immediate: true,
      handler(newValue) {
        if (!newValue && !this.epics.length) {
          this.searchEpics({ data: this.currentValue });
        }
      },
    },
  },
  methods: {
    fetchEpicsBySearchTerm(searchTerm = '') {
      this.loading = true;
      this.config
        .fetchEpics(searchTerm)
        .then((response) => {
          this.epics = Array.isArray(response) ? response : response.data;
        })
        .catch(() => createFlash({ message: __('There was a problem fetching epics.') }))
        .finally(() => {
          this.loading = false;
        });
    },
    searchEpics: debounce(function debouncedSearch({ data }) {
      this.fetchEpicsBySearchTerm(data);
    }, DEBOUNCE_DELAY),

    getEpicDisplayText(epic) {
      return `${epic.title}::&${epic[this.idProperty]}`;
    },
  },
};
</script>

<template>
  <gl-filtered-search-token
    :config="config"
    v-bind="{ ...$props, ...$attrs }"
    v-on="$listeners"
    @input="searchEpics"
  >
    <template #view="{ inputValue }">
      {{ activeEpic ? getEpicDisplayText(activeEpic) : inputValue }}
    </template>
    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="epic in defaultEpics"
        :key="epic.value"
        :value="epic.value"
      >
        {{ epic.text }}
      </gl-filtered-search-suggestion>
      <gl-dropdown-divider v-if="defaultEpics.length" />
      <gl-loading-icon v-if="loading" />
      <template v-else>
        <gl-filtered-search-suggestion
          v-for="epic in epics"
          :key="epic[idProperty]"
          :value="String(epic[idProperty])"
        >
          {{ epic.title }}
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </gl-filtered-search-token>
</template>

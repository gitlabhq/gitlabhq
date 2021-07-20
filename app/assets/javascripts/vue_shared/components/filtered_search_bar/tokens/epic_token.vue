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
  separator: '::&',
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
    idProperty() {
      return this.config.idProperty || 'iid';
    },
    currentValue() {
      const epicIid = Number(this.value.data);
      if (epicIid) {
        return epicIid;
      }
      return this.value.data;
    },
    defaultEpics() {
      return this.config.defaultEpics || DEFAULT_NONE_ANY;
    },
    activeEpic() {
      if (this.currentValue && this.epics.length) {
        // Check if current value is an epic ID.
        if (typeof this.currentValue === 'number') {
          return this.epics.find((epic) => epic[this.idProperty] === this.currentValue);
        }

        // Current value is a string.
        const [groupPath, idProperty] = this.currentValue?.split(this.$options.separator);
        return this.epics.find(
          (epic) =>
            epic.group_full_path === groupPath &&
            epic[this.idProperty] === parseInt(idProperty, 10),
        );
      }
      return null;
    },
    displayText() {
      return `${this.activeEpic?.title}${this.$options.separator}${this.activeEpic?.iid}`;
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
    fetchEpicsBySearchTerm({ epicPath = '', search = '' }) {
      this.loading = true;
      this.config
        .fetchEpics({ epicPath, search })
        .then((response) => {
          this.epics = Array.isArray(response) ? response : response.data;
        })
        .catch(() => createFlash({ message: __('There was a problem fetching epics.') }))
        .finally(() => {
          this.loading = false;
        });
    },
    searchEpics: debounce(function debouncedSearch({ data }) {
      let epicPath = this.activeEpic?.web_url;

      // When user visits the page with token value already included in filters
      // We don't have any information about selected token except for its
      // group path and iid joined by separator, so we need to manually
      // compose epic path from it.
      if (data.includes(this.$options.separator)) {
        const [groupPath, epicIid] = data.split(this.$options.separator);
        epicPath = `/groups/${groupPath}/-/epics/${epicIid}`;
      }
      this.fetchEpicsBySearchTerm({ epicPath, search: data });
    }, DEBOUNCE_DELAY),

    getValue(epic) {
      return this.config.useIdValue
        ? String(epic[this.idProperty])
        : `${epic.group_full_path}${this.$options.separator}${epic[this.idProperty]}`;
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
      {{ activeEpic ? displayText : inputValue }}
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
      <gl-loading-icon v-if="loading" size="sm" />
      <template v-else>
        <gl-filtered-search-suggestion v-for="epic in epics" :key="epic.id" :value="getValue(epic)">
          {{ epic.title }}
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </gl-filtered-search-token>
</template>

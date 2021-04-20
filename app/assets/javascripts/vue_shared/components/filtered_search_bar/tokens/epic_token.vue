<script>
import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlLoadingIcon } from '@gitlab/ui';
import { debounce } from 'lodash';

import createFlash from '~/flash';
import { isNumeric } from '~/lib/utils/number_utils';
import { __ } from '~/locale';
import { DEBOUNCE_DELAY } from '../constants';
import { stripQuotes } from '../filtered_search_utils';

export default {
  components: {
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
      /*
       * When the URL contains the epic_iid, we'd get: '123'
       */
      if (isNumeric(this.value.data)) {
        return parseInt(this.value.data, 10);
      }

      /*
       * When the token is added in current session it'd be: 'Foo::&123'
       */
      const id = this.value.data.split('::&')[1];

      if (id) {
        return parseInt(id, 10);
      }

      return this.value.data;
    },
    activeEpic() {
      const currentValueIsString = typeof this.currentValue === 'string';
      return this.epics.find(
        (epic) => epic[currentValueIsString ? 'title' : 'iid'] === this.currentValue,
      );
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
        .then(({ data }) => {
          this.epics = data;
        })
        .catch(() => createFlash({ message: __('There was a problem fetching epics.') }))
        .finally(() => {
          this.loading = false;
        });
    },
    fetchSingleEpic(iid) {
      this.loading = true;
      this.config
        .fetchSingleEpic(iid)
        .then(({ data }) => {
          this.epics = [data];
        })
        .catch(() => createFlash({ message: __('There was a problem fetching epics.') }))
        .finally(() => {
          this.loading = false;
        });
    },
    searchEpics: debounce(function debouncedSearch({ data }) {
      if (isNumeric(data)) {
        return this.fetchSingleEpic(data);
      }
      return this.fetchEpicsBySearchTerm(data);
    }, DEBOUNCE_DELAY),

    getEpicValue(epic) {
      return `${epic.title}::&${epic.iid}`;
    },
  },
  stripQuotes,
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
      <span>{{ activeEpic ? getEpicValue(activeEpic) : $options.stripQuotes(inputValue) }}</span>
    </template>
    <template #suggestions>
      <gl-loading-icon v-if="loading" />
      <template v-else>
        <gl-filtered-search-suggestion
          v-for="epic in epics"
          :key="epic.id"
          :value="getEpicValue(epic)"
        >
          <div>{{ epic.title }}</div>
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </gl-filtered-search-token>
</template>

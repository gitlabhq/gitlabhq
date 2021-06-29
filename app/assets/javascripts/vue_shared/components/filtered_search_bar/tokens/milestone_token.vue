<script>
import {
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlDropdownDivider,
  GlLoadingIcon,
} from '@gitlab/ui';
import { debounce } from 'lodash';

import createFlash from '~/flash';
import { __ } from '~/locale';
import { sortMilestonesByDueDate } from '~/milestones/milestone_utils';

import { DEFAULT_MILESTONES, DEBOUNCE_DELAY } from '../constants';
import { stripQuotes } from '../filtered_search_utils';

export default {
  components: {
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
    GlDropdownDivider,
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
      milestones: this.config.initialMilestones || [],
      defaultMilestones: this.config.defaultMilestones || DEFAULT_MILESTONES,
      loading: false,
    };
  },
  computed: {
    currentValue() {
      return this.value.data.toLowerCase();
    },
    activeMilestone() {
      return this.milestones.find(
        (milestone) => milestone.title.toLowerCase() === stripQuotes(this.currentValue),
      );
    },
  },
  watch: {
    active: {
      immediate: true,
      handler(newValue) {
        if (!newValue && !this.milestones.length) {
          this.fetchMilestoneBySearchTerm(this.value.data);
        }
      },
    },
  },
  methods: {
    fetchMilestoneBySearchTerm(searchTerm = '') {
      if (this.loading) {
        return;
      }

      this.loading = true;
      this.config
        .fetchMilestones(searchTerm)
        .then((response) => {
          const data = Array.isArray(response) ? response : response.data;
          this.milestones = data.slice().sort(sortMilestonesByDueDate);
        })
        .catch(() => createFlash({ message: __('There was a problem fetching milestones.') }))
        .finally(() => {
          this.loading = false;
        });
    },
    searchMilestones: debounce(function debouncedSearch({ data }) {
      this.fetchMilestoneBySearchTerm(data);
    }, DEBOUNCE_DELAY),
  },
};
</script>

<template>
  <gl-filtered-search-token
    :config="config"
    v-bind="{ ...$props, ...$attrs }"
    v-on="$listeners"
    @input="searchMilestones"
  >
    <template #view="{ inputValue }">
      <span>%{{ activeMilestone ? activeMilestone.title : inputValue }}</span>
    </template>
    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="milestone in defaultMilestones"
        :key="milestone.value"
        :value="milestone.value"
      >
        {{ milestone.text }}
      </gl-filtered-search-suggestion>
      <gl-dropdown-divider v-if="defaultMilestones.length" />
      <gl-loading-icon v-if="loading" />
      <template v-else>
        <gl-filtered-search-suggestion
          v-for="milestone in milestones"
          :key="milestone.id"
          :value="milestone.title"
        >
          <div>{{ milestone.title }}</div>
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </gl-filtered-search-token>
</template>

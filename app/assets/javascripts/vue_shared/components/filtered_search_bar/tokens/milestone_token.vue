<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import createFlash from '~/flash';
import { __ } from '~/locale';
import { sortMilestonesByDueDate } from '~/milestones/milestone_utils';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { DEFAULT_MILESTONES } from '../constants';
import { stripQuotes } from '../filtered_search_utils';

export default {
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
  },
  props: {
    active: {
      type: Boolean,
      required: true,
    },
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
      loading: false,
    };
  },
  computed: {
    defaultMilestones() {
      return this.config.defaultMilestones || DEFAULT_MILESTONES;
    },
  },
  methods: {
    getActiveMilestone(milestones, data) {
      return milestones.find(
        (milestone) => milestone.title.toLowerCase() === stripQuotes(data).toLowerCase(),
      );
    },
    fetchMilestones(searchTerm) {
      this.loading = true;
      this.config
        .fetchMilestones(searchTerm)
        .then((response) => {
          const data = Array.isArray(response) ? response : response.data;
          this.milestones = data.slice().sort(sortMilestonesByDueDate);
        })
        .catch(() => {
          createFlash({ message: __('There was a problem fetching milestones.') });
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
};
</script>

<template>
  <base-token
    :active="active"
    :config="config"
    :value="value"
    :default-suggestions="defaultMilestones"
    :suggestions="milestones"
    :suggestions-loading="loading"
    :get-active-token-value="getActiveMilestone"
    @fetch-suggestions="fetchMilestones"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      %{{ activeTokenValue ? activeTokenValue.title : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="milestone in suggestions"
        :key="milestone.id"
        :value="milestone.title"
      >
        {{ milestone.title }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>

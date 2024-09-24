<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import searchMilestonesQuery from '~/issues/list/queries/search_milestones.query.graphql';
import { sortMilestonesByDueDate } from '~/milestones/utils';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { stripQuotes } from '~/lib/utils/text_utility';
import { DEFAULT_MILESTONES } from '../constants';

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
    namespace() {
      return this.config.isProject ? WORKSPACE_PROJECT : WORKSPACE_GROUP;
    },
    fetchMilestonesQuery() {
      return this.config.fetchMilestones
        ? this.config.fetchMilestones
        : this.fetchMilestonesBySearchTerm;
    },
  },
  methods: {
    getActiveMilestone(milestones, data) {
      /* We need to check default milestones against the value not the
       * title because there is a discrepancy between the value graphql
       * accepts and the title.
       * https://gitlab.com/gitlab-org/gitlab/-/issues/337687#note_648058797
       */

      return (
        milestones.find(
          (milestone) =>
            this.getMilestoneTitle(milestone).toLowerCase() === stripQuotes(data).toLowerCase(),
        ) || this.defaultMilestones.find(({ value }) => value === data)
      );
    },
    getMilestoneTitle(milestone) {
      return milestone.title;
    },
    fetchMilestonesBySearchTerm(search) {
      return this.$apollo
        .query({
          query: searchMilestonesQuery,
          variables: { fullPath: this.config.fullPath, search, isProject: this.config.isProject },
        })
        .then(({ data }) => data[this.namespace]?.milestones.nodes);
    },
    fetchMilestones(searchTerm) {
      this.loading = true;
      this.fetchMilestonesQuery(searchTerm)
        .then((response) => {
          const data = Array.isArray(response) ? response : response.data;

          const uniqueData = data.reduce((acc, current) => {
            const existingItem = acc.find((item) => item.title === current.title);

            if (!existingItem) {
              acc.push(current);
            }

            return acc;
          }, []);

          if (this.config.shouldSkipSort) {
            this.milestones = uniqueData;
          } else {
            this.milestones = uniqueData.slice().sort(sortMilestonesByDueDate);
          }
        })
        .catch(() => {
          createAlert({ message: __('There was a problem fetching milestones.') });
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
    :value-identifier="getMilestoneTitle"
    v-bind="$attrs"
    @fetch-suggestions="fetchMilestones"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      %{{ activeTokenValue ? getMilestoneTitle(activeTokenValue) : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="milestone in suggestions"
        :key="milestone.id"
        :value="getMilestoneTitle(milestone)"
      >
        {{ getMilestoneTitle(milestone) }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>

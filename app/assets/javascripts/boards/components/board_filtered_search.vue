<script>
import { pickBy, isEmpty, mapValues } from 'lodash';
import { getIdFromGraphQLId, isGid } from '~/graphql_shared/utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { updateHistory, setUrlParams, queryToObject } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import {
  FILTER_ANY,
  FILTERED_SEARCH_TERM,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_EPIC,
  TOKEN_TYPE_HEALTH,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_WEIGHT,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { AssigneeFilterType, GroupByParamType } from 'ee_else_ce/boards/constants';

export default {
  i18n: {
    search: __('Search'),
  },
  components: { FilteredSearch },
  inject: ['initialFilterParams'],
  props: {
    isSwimlanesOn: {
      type: Boolean,
      required: false,
      default: false,
    },
    tokens: {
      type: Array,
      required: true,
    },
    eeFilters: {
      required: false,
      type: Object,
      default: () => ({}),
    },
    filters: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      filterParams: this.initialFilterParams,
      filteredSearchKey: 0,
    };
  },
  computed: {
    getFilteredSearchValue() {
      const {
        authorUsername,
        labelName,
        assigneeUsername,
        assigneeId,
        search,
        milestoneTitle,
        iterationId,
        iterationCadenceId,
        types,
        weight,
        epicId,
        myReactionEmoji,
        releaseTag,
        confidential,
        healthStatus,
      } = this.filterParams;
      const filteredSearchValue = [];

      if (authorUsername) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_AUTHOR,
          value: { data: authorUsername, operator: '=' },
        });
      }

      if (assigneeUsername) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_ASSIGNEE,
          value: { data: assigneeUsername, operator: '=' },
        });
      }

      if (assigneeId) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_ASSIGNEE,
          value: { data: assigneeId, operator: '=' },
        });
      }

      if (types) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_TYPE,
          value: { data: types, operator: '=' },
        });
      }

      if (labelName?.length) {
        filteredSearchValue.push(
          ...labelName.map((label) => ({
            type: TOKEN_TYPE_LABEL,
            value: { data: label, operator: '=' },
          })),
        );
      }

      if (milestoneTitle) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_MILESTONE,
          value: { data: milestoneTitle, operator: '=' },
        });
      }

      let iterationData = null;

      if (iterationId && iterationCadenceId) {
        iterationData = `${iterationId}&${iterationCadenceId}`;
      } else if (iterationCadenceId) {
        iterationData = `${FILTER_ANY}&${iterationCadenceId}`;
      } else if (iterationId) {
        iterationData = iterationId;
      }

      if (iterationData) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_ITERATION,
          value: { data: iterationData, operator: '=' },
        });
      }

      if (weight) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_WEIGHT,
          value: { data: weight, operator: '=' },
        });
      }

      if (myReactionEmoji) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_MY_REACTION,
          value: { data: myReactionEmoji, operator: '=' },
        });
      }

      if (releaseTag) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_RELEASE,
          value: { data: releaseTag, operator: '=' },
        });
      }

      if (confidential !== undefined) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_CONFIDENTIAL,
          value: { data: confidential },
        });
      }

      if (epicId) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_EPIC,
          value: { data: epicId, operator: '=' },
        });
      }

      if (healthStatus) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_HEALTH,
          value: { data: healthStatus, operator: '=' },
        });
      }

      if (this.filterParams['not[authorUsername]']) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_AUTHOR,
          value: { data: this.filterParams['not[authorUsername]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[milestoneTitle]']) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_MILESTONE,
          value: { data: this.filterParams['not[milestoneTitle]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[iterationId]']) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_ITERATION,
          value: { data: this.filterParams['not[iterationId]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[weight]']) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_WEIGHT,
          value: { data: this.filterParams['not[weight]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[assigneeUsername]']) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_ASSIGNEE,
          value: { data: this.filterParams['not[assigneeUsername]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[labelName]']) {
        filteredSearchValue.push(
          ...this.filterParams['not[labelName]'].map((label) => ({
            type: TOKEN_TYPE_LABEL,
            value: { data: label, operator: '!=' },
          })),
        );
      }

      if (this.filterParams['not[types]']) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_TYPE,
          value: { data: this.filterParams['not[types]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[epicId]']) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_EPIC,
          value: { data: this.filterParams['not[epicId]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[myReactionEmoji]']) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_MY_REACTION,
          value: { data: this.filterParams['not[myReactionEmoji]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[releaseTag]']) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_RELEASE,
          value: { data: this.filterParams['not[releaseTag]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[healthStatus]']) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_HEALTH,
          value: { data: this.filterParams['not[healthStatus]'], operator: '!=' },
        });
      }

      if (search) {
        filteredSearchValue.push(search);
      }

      return filteredSearchValue;
    },
    urlParams() {
      const {
        authorUsername,
        labelName,
        assigneeUsername,
        assigneeId,
        search,
        milestoneTitle,
        types,
        weight,
        epicId,
        myReactionEmoji,
        iterationId,
        iterationCadenceId,
        releaseTag,
        confidential,
        healthStatus,
      } = this.filterParams;
      let iteration = iterationId;
      let cadence = iterationCadenceId;
      let notParams = {};

      if (Object.prototype.hasOwnProperty.call(this.filterParams, 'not')) {
        notParams = pickBy(
          {
            'not[label_name][]': this.filterParams.not.labelName,
            'not[author_username]': this.filterParams.not.authorUsername,
            'not[assignee_username]': this.filterParams.not.assigneeUsername,
            'not[types]': this.filterParams.not.types,
            'not[milestone_title]': this.filterParams.not.milestoneTitle,
            'not[weight]': this.filterParams.not.weight,
            'not[epic_id]': this.filterParams.not.epicId,
            'not[my_reaction_emoji]': this.filterParams.not.myReactionEmoji,
            'not[iteration_id]': this.filterParams.not.iterationId,
            'not[release_tag]': this.filterParams.not.releaseTag,
            'not[health_status]': this.filterParams.not.healthStatus,
          },
          undefined,
        );
      }

      if (iterationId?.includes('&')) {
        [iteration, cadence] = iterationId.split('&');
      }

      return mapValues(
        {
          ...notParams,
          author_username: authorUsername,
          'label_name[]': labelName,
          assignee_username: assigneeUsername,
          assignee_id: assigneeId,
          milestone_title: milestoneTitle,
          iteration_id: iteration,
          iteration_cadence_id: cadence,
          search,
          types,
          weight,
          epic_id: isGid(epicId) ? getIdFromGraphQLId(epicId) : epicId,
          my_reaction_emoji: myReactionEmoji,
          release_tag: releaseTag,
          confidential,
          health_status: healthStatus,
          group_by: this.isSwimlanesOn ? GroupByParamType.epic : undefined,
        },
        (value) => {
          if (value || value === false) {
            // note: need to check array for labels.
            if (Array.isArray(value)) {
              return value.map((valueItem) => encodeURIComponent(valueItem));
            }
            return encodeURIComponent(value);
          }

          return value;
        },
      );
    },
  },
  watch: {
    filters: {
      handler(updatedFilters) {
        this.filterParams = { ...this.filterParams, ...updatedFilters };
        this.filteredSearchKey += 1;
      },
      immediate: true,
    },
  },
  created() {
    if (!isEmpty(this.eeFilters)) {
      this.filterParams = this.eeFilters;
      this.$emit('setFilters', this.formattedFilterParams);
    }
  },
  methods: {
    formattedFilterParams() {
      const rawFilterParams = queryToObject(window.location.search, { gatherArrays: true });
      const filtersCopy = convertObjectPropsToCamelCase(rawFilterParams, {});
      this.filterParams = filtersCopy;

      return filtersCopy;
    },
    updateTokens() {
      this.$emit('setFilters', this.formattedFilterParams());
      this.filteredSearchKey += 1;
    },
    handleFilter(filters) {
      this.filterParams = this.getFilterParams(filters);

      updateHistory({
        url: setUrlParams(this.urlParams, window.location.href, true, false, true),
        title: document.title,
        replace: true,
      });

      this.$emit('setFilters', this.formattedFilterParams());
    },
    getFilterParams(filters = []) {
      const notFilters = filters.filter((item) => item.value.operator === '!=');
      const equalsFilters = filters.filter(
        (item) => item?.value?.operator === '=' || item.type === FILTERED_SEARCH_TERM,
      );

      return { ...this.generateParams(equalsFilters), not: { ...this.generateParams(notFilters) } };
    },
    generateParams(filters = []) {
      const filterParams = {};
      const labels = [];

      filters.forEach((filter) => {
        switch (filter.type) {
          case TOKEN_TYPE_AUTHOR:
            filterParams.authorUsername = filter.value.data;
            break;
          case TOKEN_TYPE_ASSIGNEE:
            if (Object.values(AssigneeFilterType).includes(filter.value.data)) {
              filterParams.assigneeId = filter.value.data;
            } else {
              filterParams.assigneeUsername = filter.value.data;
            }
            break;
          case TOKEN_TYPE_TYPE:
            filterParams.types = filter.value.data;
            break;
          case TOKEN_TYPE_LABEL:
            labels.push(filter.value.data);
            break;
          case TOKEN_TYPE_MILESTONE:
            filterParams.milestoneTitle = filter.value.data;
            break;
          case TOKEN_TYPE_ITERATION:
            filterParams.iterationId = filter.value.data;
            break;
          case TOKEN_TYPE_WEIGHT:
            filterParams.weight = filter.value.data;
            break;
          case TOKEN_TYPE_EPIC:
            filterParams.epicId = filter.value.data;
            break;
          case TOKEN_TYPE_MY_REACTION:
            filterParams.myReactionEmoji = filter.value.data;
            break;
          case TOKEN_TYPE_RELEASE:
            filterParams.releaseTag = filter.value.data;
            break;
          case TOKEN_TYPE_CONFIDENTIAL:
            filterParams.confidential = filter.value.data;
            break;
          case FILTERED_SEARCH_TERM:
            if (filter.value.data) {
              filterParams.search = filter.value.data;
            }
            break;
          case TOKEN_TYPE_HEALTH:
            filterParams.healthStatus = filter.value.data;
            break;
          default:
            break;
        }
      });

      if (labels.length) {
        filterParams.labelName = labels;
      }

      return filterParams;
    },
  },
};
</script>

<template>
  <filtered-search
    :key="filteredSearchKey"
    class="gl-w-full"
    namespace=""
    terms-as-tokens
    :tokens="tokens"
    :search-input-placeholder="$options.i18n.search"
    :initial-filter-value="getFilteredSearchValue"
    @onFilter="handleFilter"
  />
</template>

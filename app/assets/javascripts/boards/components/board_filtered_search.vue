<script>
import { pickBy, isEmpty, mapValues } from 'lodash';
import { mapActions } from 'vuex';
import { getIdFromGraphQLId, isGid } from '~/graphql_shared/utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { updateHistory, setUrlParams, queryToObject } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import {
  FILTERED_SEARCH_TERM,
  FILTER_ANY,
  TOKEN_TYPE_HEALTH,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { AssigneeFilterType } from '~/boards/constants';
import eventHub from '../eventhub';

export default {
  i18n: {
    search: __('Search'),
  },
  components: { FilteredSearch },
  inject: ['initialFilterParams'],
  props: {
    tokens: {
      type: Array,
      required: true,
    },
    eeFilters: {
      required: false,
      type: Object,
      default: () => ({}),
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
          type: 'author',
          value: { data: authorUsername, operator: '=' },
        });
      }

      if (assigneeUsername) {
        filteredSearchValue.push({
          type: 'assignee',
          value: { data: assigneeUsername, operator: '=' },
        });
      }

      if (assigneeId) {
        filteredSearchValue.push({
          type: 'assignee',
          value: { data: assigneeId, operator: '=' },
        });
      }

      if (types) {
        filteredSearchValue.push({
          type: 'type',
          value: { data: types, operator: '=' },
        });
      }

      if (labelName?.length) {
        filteredSearchValue.push(
          ...labelName.map((label) => ({
            type: 'label',
            value: { data: label, operator: '=' },
          })),
        );
      }

      if (milestoneTitle) {
        filteredSearchValue.push({
          type: 'milestone',
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
          type: 'iteration',
          value: { data: iterationData, operator: '=' },
        });
      }

      if (weight) {
        filteredSearchValue.push({
          type: 'weight',
          value: { data: weight, operator: '=' },
        });
      }

      if (myReactionEmoji) {
        filteredSearchValue.push({
          type: 'my-reaction',
          value: { data: myReactionEmoji, operator: '=' },
        });
      }

      if (releaseTag) {
        filteredSearchValue.push({
          type: 'release',
          value: { data: releaseTag, operator: '=' },
        });
      }

      if (confidential !== undefined) {
        filteredSearchValue.push({
          type: 'confidential',
          value: { data: confidential },
        });
      }

      if (epicId) {
        filteredSearchValue.push({
          type: 'epic',
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
          type: 'author',
          value: { data: this.filterParams['not[authorUsername]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[milestoneTitle]']) {
        filteredSearchValue.push({
          type: 'milestone',
          value: { data: this.filterParams['not[milestoneTitle]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[iterationId]']) {
        filteredSearchValue.push({
          type: 'iteration',
          value: { data: this.filterParams['not[iterationId]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[weight]']) {
        filteredSearchValue.push({
          type: 'weight',
          value: { data: this.filterParams['not[weight]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[assigneeUsername]']) {
        filteredSearchValue.push({
          type: 'assignee',
          value: { data: this.filterParams['not[assigneeUsername]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[labelName]']) {
        filteredSearchValue.push(
          ...this.filterParams['not[labelName]'].map((label) => ({
            type: 'label',
            value: { data: label, operator: '!=' },
          })),
        );
      }

      if (this.filterParams['not[types]']) {
        filteredSearchValue.push({
          type: 'type',
          value: { data: this.filterParams['not[types]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[epicId]']) {
        filteredSearchValue.push({
          type: 'epic',
          value: { data: this.filterParams['not[epicId]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[myReactionEmoji]']) {
        filteredSearchValue.push({
          type: 'my-reaction',
          value: { data: this.filterParams['not[myReactionEmoji]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[releaseTag]']) {
        filteredSearchValue.push({
          type: 'release',
          value: { data: this.filterParams['not[releaseTag]'], operator: '!=' },
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
          [TOKEN_TYPE_HEALTH]: healthStatus,
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
  created() {
    eventHub.$on('updateTokens', this.updateTokens);
    if (!isEmpty(this.eeFilters)) {
      this.filterParams = this.eeFilters;
    }
  },
  beforeDestroy() {
    eventHub.$off('updateTokens', this.updateTokens);
  },
  methods: {
    ...mapActions(['performSearch']),
    updateTokens() {
      const rawFilterParams = queryToObject(window.location.search, { gatherArrays: true });
      this.filterParams = convertObjectPropsToCamelCase(rawFilterParams, {});
      this.filteredSearchKey += 1;
    },
    handleFilter(filters) {
      this.filterParams = this.getFilterParams(filters);

      updateHistory({
        url: setUrlParams(this.urlParams, window.location.href, true, false, true),
        title: document.title,
        replace: true,
      });

      this.performSearch();
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
      const plainText = [];

      filters.forEach((filter) => {
        switch (filter.type) {
          case 'author':
            filterParams.authorUsername = filter.value.data;
            break;
          case 'assignee':
            if (Object.values(AssigneeFilterType).includes(filter.value.data)) {
              filterParams.assigneeId = filter.value.data;
            } else {
              filterParams.assigneeUsername = filter.value.data;
            }
            break;
          case 'type':
            filterParams.types = filter.value.data;
            break;
          case 'label':
            labels.push(filter.value.data);
            break;
          case 'milestone':
            filterParams.milestoneTitle = filter.value.data;
            break;
          case 'iteration':
            filterParams.iterationId = filter.value.data;
            break;
          case 'weight':
            filterParams.weight = filter.value.data;
            break;
          case 'epic':
            filterParams.epicId = filter.value.data;
            break;
          case 'my-reaction':
            filterParams.myReactionEmoji = filter.value.data;
            break;
          case 'release':
            filterParams.releaseTag = filter.value.data;
            break;
          case 'confidential':
            filterParams.confidential = filter.value.data;
            break;
          case 'filtered-search-term':
            if (filter.value.data) plainText.push(filter.value.data);
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

      if (plainText.length) {
        filterParams.search = plainText.join(' ');
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
    :tokens="tokens"
    :search-input-placeholder="$options.i18n.search"
    :initial-filter-value="getFilteredSearchValue"
    @onFilter="handleFilter"
  />
</template>

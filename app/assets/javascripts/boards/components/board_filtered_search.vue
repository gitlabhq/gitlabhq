<script>
import { pickBy, isEmpty, mapValues } from 'lodash-es';
import { getIdFromGraphQLId, isGid } from '~/graphql_shared/utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { updateHistory, setUrlParams, queryToObject } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import {
  FILTER_ANY,
  FILTERED_SEARCH_TERM,
  OPERATOR_IS,
  OPERATOR_NOT,
  OPERATOR_OR,
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
  TOKEN_TYPE_STATUS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import workItemTypesConfigurationQuery from '~/work_items/graphql/work_item_types_configuration.query.graphql';
import { convertOldTypeTokenEnumToGid } from '~/work_items/list/utils';
import { AssigneeFilterType, GroupByParamType } from 'ee_else_ce/boards/constants';

const customFieldRegex = /custom-field\[([0-9]+)\]/g;

// Negated multi-value params arrive as arrays. Return the array only when there
// is more than one value so multi-select tokens keep every value; a single value
// stays a scalar, which non-multi-select tokens (e.g. the epic board's) require.
const negatedTokenData = (value) => {
  const values = [].concat(value);
  return values.length > 1 ? values : values[0];
};

export default {
  name: 'BoardFilteredSearch',
  i18n: {
    search: __('Search'),
  },
  components: { FilteredSearchBar },
  inject: ['fullPath', 'initialFilterParams', 'hasCustomFieldsFeature'],
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
  emits: ['set-filters'],
  data() {
    return {
      filterParams: this.initialFilterParams,
      filteredSearchKey: 0,
      workItemTypesConfiguration: [],
    };
  },
  apollo: {
    workItemTypesConfiguration: {
      query: workItemTypesConfigurationQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data?.namespace?.workItemTypes?.nodes || [];
      },
      result() {
        // TODO remove when we no longer need to convert old type=ISSUE params to new type=1 params
        if (this.getFilteredSearchValue.some((token) => token.type === TOKEN_TYPE_TYPE)) {
          const tokens = convertOldTypeTokenEnumToGid(
            this.getFilteredSearchValue,
            this.workItemTypesConfiguration,
          );
          this.handleFilter(tokens);
        }
      },
    },
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
        weight,
        epicId,
        myReactionEmoji,
        releaseTag,
        confidential,
        healthStatus,
        status,
        ...otherValues
      } = this.filterParams;

      // `type[]` is the current param; `types` is read as a fallback so legacy
      // bookmarked board URLs keep applying the type filter.
      const type = this.filterParams.type ?? this.filterParams.types;

      const filteredSearchValue = [];

      if (this.hasCustomFieldsFeature) {
        for (const [key, value] of Object.entries(otherValues)) {
          if (key.match(customFieldRegex)) {
            filteredSearchValue.push({
              type: key,
              value: { data: value, operator: '=' },
            });
          }
        }
      }

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

      if (Array.isArray(type) && type.length > 1) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_TYPE,
          value: { data: type, operator: OPERATOR_OR },
        });
      } else if (type) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_TYPE,
          value: { data: Array.isArray(type) ? type[0] : type, operator: OPERATOR_IS },
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

      if (status) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_STATUS,
          value: { data: status, operator: '=' },
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

      // `not[authorUsernames]` is the multi-value negation param; the singular
      // `not[authorUsername]` is read as a fallback so legacy bookmarked URLs
      // keep working.
      const notAuthors =
        this.filterParams['not[authorUsernames]'] ?? this.filterParams['not[authorUsername]'];
      if (notAuthors) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_AUTHOR,
          value: { data: negatedTokenData(notAuthors), operator: OPERATOR_NOT },
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
          value: {
            data: negatedTokenData(this.filterParams['not[assigneeUsername]']),
            operator: OPERATOR_NOT,
          },
        });
      }

      if (this.filterParams['not[labelName]']) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_LABEL,
          value: {
            data: negatedTokenData(this.filterParams['not[labelName]']),
            operator: OPERATOR_NOT,
          },
        });
      }

      const notType = this.filterParams['not[type]'] ?? this.filterParams['not[types]'];
      if (notType) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_TYPE,
          value: { data: negatedTokenData(notType), operator: OPERATOR_NOT },
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

      if (this.filterParams['or[authorUsername]']) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_AUTHOR,
          value: { data: this.filterParams['or[authorUsername]'], operator: OPERATOR_OR },
        });
      }

      if (this.filterParams['or[assigneeUsername]']) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_ASSIGNEE,
          value: { data: this.filterParams['or[assigneeUsername]'], operator: OPERATOR_OR },
        });
      }

      if (this.filterParams['or[labelName]']) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_LABEL,
          value: { data: this.filterParams['or[labelName]'], operator: OPERATOR_OR },
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
        type,
        weight,
        epicId,
        myReactionEmoji,
        iterationId,
        iterationCadenceId,
        releaseTag,
        confidential,
        healthStatus,
        status,
        ...otherValues
      } = this.filterParams;

      let iteration = iterationId;
      let cadence = iterationCadenceId;
      let notParams = {};
      let orParams = {};
      const customFieldParams = {};

      if (this.hasCustomFieldsFeature) {
        Object.entries(otherValues).forEach(([key, value]) => {
          if (key.match(customFieldRegex)) {
            customFieldParams[key] = value;
          }
        });
      }

      if (Object.prototype.hasOwnProperty.call(this.filterParams, 'not')) {
        notParams = pickBy(
          {
            'not[label_name][]': this.filterParams.not.labelName,
            // Author and assignee negation are multi-value (multiSelect), so use
            // array-notation keys that round-trip through queryToObject. Author
            // uses the additive plural `author_usernames` param so it maps to the
            // new list argument without breaking the single-value `authorUsername`.
            'not[author_usernames][]': this.filterParams.not.authorUsername,
            'not[assignee_username][]': this.filterParams.not.assigneeUsername,
            'not[type][]': this.filterParams.not.type,
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

      if (Object.prototype.hasOwnProperty.call(this.filterParams, 'or')) {
        // The `or[field][]` param naming follows the work items list. The keys
        // are pre-encoded so the bracket characters survive the whole-query-string
        // decodeURIComponent pass in handleFilter and stay as `or%5B...%5D%5B%5D`
        // (unlike the work items list, which keeps literal brackets on the wire).
        orParams = pickBy(
          {
            [encodeURIComponent('or[label_name][]')]: this.filterParams.or.labelName,
            [encodeURIComponent('or[author_username][]')]: this.filterParams.or.authorUsername,
            [encodeURIComponent('or[assignee_username][]')]: this.filterParams.or.assigneeUsername,
          },
          undefined,
        );
      }

      if (iterationId?.includes('&')) {
        [iteration, cadence] = iterationId.split('&');
      }

      // Type serializes as the array param `type[]` (param naming follows the
      // work items list) for both a single "is" type and a multi "is one of"
      // selection. The key is pre-encoded so the bracket characters survive the
      // whole-query-string decodeURIComponent pass in handleFilter and stay as
      // `type%5B%5D` (unlike the work items list, which keeps literal brackets).
      const typeParams = type === undefined ? {} : { [encodeURIComponent('type[]')]: type };

      return mapValues(
        {
          ...customFieldParams,
          ...notParams,
          ...orParams,
          ...typeParams,
          author_username: authorUsername,
          'label_name[]': labelName,
          assignee_username: assigneeUsername,
          assignee_id: assigneeId,
          milestone_title: milestoneTitle,
          iteration_id: iteration,
          iteration_cadence_id: cadence,
          search,
          weight,
          status,
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
      this.$emit('set-filters', this.formattedFilterParams);
    }
  },
  methods: {
    formattedFilterParams() {
      const rawFilterParams = queryToObject(window.location.search, { gatherArrays: true });
      const filtersCopy = convertObjectPropsToCamelCase(rawFilterParams, {});
      this.filterParams = filtersCopy;

      return filtersCopy;
    },
    // eslint-disable-next-line vue/no-unused-properties -- updateTokens() is called via $refs by ee/boards/components/board_filtered_search.vue
    updateTokens() {
      this.$emit('set-filters', this.formattedFilterParams());
      this.filteredSearchKey += 1;
    },
    handleFilter(filters) {
      this.filterParams = this.getFilterParams(filters);

      updateHistory({
        url: setUrlParams(this.urlParams, {
          url: window.location.href,
          clearParams: true,
          decodeParams: true,
        }),
        title: document.title,
        replace: true,
      });

      this.$emit('set-filters', this.formattedFilterParams());
    },
    getFilterParams(filters = []) {
      // A "type is one of" (OR) selection maps to workItemTypeIds, a list on
      // BoardIssueInput where multiple IDs are already treated as OR by the
      // backend. There is no or[type] union field, so route it as a normal (IS)
      // multi-value filter rather than an OR-bucket filter.
      const normalizedFilters = filters.map((filter) => {
        if (filter.type === TOKEN_TYPE_TYPE && filter.value.operator === OPERATOR_OR) {
          return { ...filter, value: { ...filter.value, operator: OPERATOR_IS } };
        }
        return filter;
      });

      const notFilters = normalizedFilters.filter((item) => item.value.operator === OPERATOR_NOT);
      const orFilters = normalizedFilters.filter((item) => item.value.operator === OPERATOR_OR);
      const equalsFilters = normalizedFilters.filter(
        (item) => item?.value?.operator === OPERATOR_IS || item.type === FILTERED_SEARCH_TERM,
      );

      return {
        ...this.generateParams(equalsFilters),
        not: { ...this.generateParams(notFilters) },
        or: { ...this.generateParams(orFilters) },
      };
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
            filterParams.type = Array.isArray(filter.value.data)
              ? filter.value.data
              : [filter.value.data];
            break;
          case TOKEN_TYPE_LABEL:
            if (Array.isArray(filter.value.data)) {
              labels.push(...filter.value.data);
            } else {
              labels.push(filter.value.data);
            }
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
          case TOKEN_TYPE_STATUS:
            filterParams.status = filter.value.data;
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
            if (this.hasCustomFieldsFeature && filter.type.match(customFieldRegex)) {
              filterParams[filter.type] = filter.value.data;
            }
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
  <filtered-search-bar
    :key="filteredSearchKey"
    class="gl-w-full"
    namespace=""
    terms-as-tokens
    show-friendly-text
    :tokens="tokens"
    :search-input-placeholder="$options.i18n.search"
    :initial-filter-value="getFilteredSearchValue"
    @on-filter="handleFilter"
  />
</template>

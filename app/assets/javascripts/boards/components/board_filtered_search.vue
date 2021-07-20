<script>
import { pickBy } from 'lodash';
import { mapActions } from 'vuex';
import { updateHistory, setUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

export default {
  i18n: {
    search: __('Search'),
    label: __('Label'),
    author: __('Author'),
  },
  components: { FilteredSearch },
  inject: ['initialFilterParams'],
  props: {
    tokens: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      filterParams: this.initialFilterParams,
    };
  },
  computed: {
    urlParams() {
      const { authorUsername, labelName, assigneeUsername, search } = this.filterParams;
      let notParams = {};

      if (Object.prototype.hasOwnProperty.call(this.filterParams, 'not')) {
        notParams = pickBy(
          {
            'not[label_name][]': this.filterParams.not.labelName,
            'not[author_username]': this.filterParams.not.authorUsername,
            'not[assignee_username]': this.filterParams.not.assigneeUsername,
          },
          undefined,
        );
      }

      return {
        ...notParams,
        author_username: authorUsername,
        'label_name[]': labelName,
        assignee_username: assigneeUsername,
        search,
      };
    },
  },
  methods: {
    ...mapActions(['performSearch']),
    handleFilter(filters) {
      this.filterParams = this.getFilterParams(filters);

      updateHistory({
        url: setUrlParams(this.urlParams, window.location.href, true, false, true),
        title: document.title,
        replace: true,
      });

      this.performSearch();
    },
    getFilteredSearchValue() {
      const { authorUsername, labelName, assigneeUsername, search } = this.filterParams;
      const filteredSearchValue = [];

      if (authorUsername) {
        filteredSearchValue.push({
          type: 'author_username',
          value: { data: authorUsername, operator: '=' },
        });
      }

      if (assigneeUsername) {
        filteredSearchValue.push({
          type: 'assignee_username',
          value: { data: assigneeUsername, operator: '=' },
        });
      }

      if (labelName?.length) {
        filteredSearchValue.push(
          ...labelName.map((label) => ({
            type: 'label_name',
            value: { data: label, operator: '=' },
          })),
        );
      }

      if (this.filterParams['not[authorUsername]']) {
        filteredSearchValue.push({
          type: 'author_username',
          value: { data: this.filterParams['not[authorUsername]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[assigneeUsername]']) {
        filteredSearchValue.push({
          type: 'assignee_username',
          value: { data: this.filterParams['not[assigneeUsername]'], operator: '!=' },
        });
      }

      if (this.filterParams['not[labelName]']) {
        filteredSearchValue.push(
          ...this.filterParams['not[labelName]'].map((label) => ({
            type: 'label_name',
            value: { data: label, operator: '!=' },
          })),
        );
      }

      if (search) {
        filteredSearchValue.push(search);
      }

      return filteredSearchValue;
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
          case 'author_username':
            filterParams.authorUsername = filter.value.data;
            break;
          case 'assignee_username':
            filterParams.assigneeUsername = filter.value.data;
            break;
          case 'label_name':
            labels.push(filter.value.data);
            break;
          case 'filtered-search-term':
            if (filter.value.data) plainText.push(filter.value.data);
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
    class="gl-w-full"
    namespace=""
    :tokens="tokens"
    :search-input-placeholder="$options.i18n.search"
    :initial-filter-value="getFilteredSearchValue()"
    @onFilter="handleFilter"
  />
</template>

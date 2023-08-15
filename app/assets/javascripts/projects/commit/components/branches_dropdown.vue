<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import { debounce, uniqBy } from 'lodash';
import {
  I18N_NO_RESULTS_MESSAGE,
  I18N_BRANCH_HEADER,
  I18N_BRANCH_SEARCH_PLACEHOLDER,
} from '../constants';

export default {
  name: 'BranchesDropdown',
  components: {
    GlCollapsibleListbox,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
  i18n: {
    noResultsMessage: I18N_NO_RESULTS_MESSAGE,
    branchHeaderTitle: I18N_BRANCH_HEADER,
    branchSearchPlaceholder: I18N_BRANCH_SEARCH_PLACEHOLDER,
  },
  data() {
    return {
      searchTerm: '',
    };
  },
  computed: {
    ...mapGetters(['joinedBranches']),
    ...mapState(['isFetching', 'branch']),
    listboxItems() {
      const selectedItem = { value: this.branch, text: this.branch };
      const transformedList = this.joinedBranches.map((value) => ({ value, text: value }));

      if (this.searchTerm) {
        return transformedList;
      }

      // Add selected item to top of list if not searching
      return uniqBy([selectedItem].concat(transformedList), 'value');
    },
  },
  mounted() {
    this.fetchBranches();
  },
  methods: {
    ...mapActions(['fetchBranches']),
    selectBranch(branch) {
      this.$emit('input', branch);
    },
    debouncedSearch: debounce(function debouncedSearch() {
      this.fetchBranches(this.searchTerm);
    }, 250),
    searchTermChanged(value) {
      this.searchTerm = value.trim();
      this.debouncedSearch(value);
    },
  },
};
</script>
<template>
  <gl-collapsible-listbox
    class="gl-max-w-full"
    :header-text="$options.i18n.branchHeaderTitle"
    :toggle-text="value"
    toggle-class="gl-w-full"
    :items="listboxItems"
    searchable
    :search-placeholder="$options.i18n.branchSearchPlaceholder"
    :searching="isFetching"
    :selected="value"
    :no-results-text="$options.i18n.noResultsMessage"
    @search="searchTermChanged"
    @select="selectBranch"
  />
</template>

<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
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
    blanked: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  i18n: {
    noResultsMessage: I18N_NO_RESULTS_MESSAGE,
    branchHeaderTitle: I18N_BRANCH_HEADER,
    branchSearchPlaceholder: I18N_BRANCH_SEARCH_PLACEHOLDER,
  },
  data() {
    return {
      searchTerm: this.blanked ? '' : this.value,
    };
  },
  computed: {
    ...mapGetters(['joinedBranches']),
    ...mapState(['isFetching']),
    filteredResults() {
      const lowerCasedSearchTerm = this.searchTerm.toLowerCase();
      return this.joinedBranches.filter((resultString) =>
        resultString.toLowerCase().includes(lowerCasedSearchTerm),
      );
    },
    listboxItems() {
      return this.filteredResults.map((value) => ({ value, text: value }));
    },
  },
  watch: {
    // Parent component can set the branch value (e.g. when the user selects a different project)
    // and we need to keep the search term in sync with the selected value
    value(val) {
      this.searchTermChanged(val);
    },
  },
  mounted() {
    this.fetchBranches(this.searchTerm);
  },
  methods: {
    ...mapActions(['fetchBranches']),
    selectBranch(branch) {
      this.$emit('selectBranch', branch);
    },
    searchTermChanged(value) {
      this.searchTerm = value;
      this.fetchBranches(value);
    },
  },
};
</script>
<template>
  <gl-collapsible-listbox
    :header-text="$options.i18n.branchHeaderTitle"
    :toggle-text="value"
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

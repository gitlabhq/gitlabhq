<script>
import {
  GlDropdown,
  GlSearchBoxByType,
  GlDropdownItem,
  GlDropdownText,
  GlLoadingIcon,
} from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { I18N_DROPDOWN } from '../constants';

export default {
  name: 'BranchesDropdown',
  components: {
    GlDropdown,
    GlSearchBoxByType,
    GlDropdownItem,
    GlDropdownText,
    GlLoadingIcon,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
  i18n: I18N_DROPDOWN,
  data() {
    return {
      searchTerm: this.value,
    };
  },
  computed: {
    ...mapGetters(['joinedBranches']),
    ...mapState(['isFetching', 'branch', 'branches']),
    filteredResults() {
      const lowerCasedSearchTerm = this.searchTerm.toLowerCase();
      return this.joinedBranches.filter((resultString) =>
        resultString.toLowerCase().includes(lowerCasedSearchTerm),
      );
    },
  },
  mounted() {
    this.fetchBranches(this.searchTerm);
  },
  methods: {
    ...mapActions(['fetchBranches']),
    selectBranch(branch) {
      this.$emit('selectBranch', branch);
      this.searchTerm = branch; // enables isSelected to work as expected
    },
    isSelected(selectedBranch) {
      return selectedBranch === this.branch;
    },
    searchTermChanged(value) {
      this.searchTerm = value;
      this.fetchBranches(value);
    },
  },
};
</script>
<template>
  <gl-dropdown :text="value" :header-text="$options.i18n.headerTitle">
    <gl-search-box-by-type
      :value="searchTerm"
      trim
      autocomplete="off"
      :debounce="250"
      :placeholder="$options.i18n.searchPlaceholder"
      data-testid="dropdown-search-box"
      @input="searchTermChanged"
    />
    <gl-dropdown-item
      v-for="branch in filteredResults"
      v-show="!isFetching"
      :key="branch"
      :name="branch"
      :is-checked="isSelected(branch)"
      is-check-item
      @click="selectBranch(branch)"
    >
      {{ branch }}
    </gl-dropdown-item>
    <gl-dropdown-text v-show="isFetching" data-testid="dropdown-text-loading-icon">
      <gl-loading-icon class="gl-mx-auto" />
    </gl-dropdown-text>
    <gl-dropdown-text
      v-if="!filteredResults.length && !isFetching"
      data-testid="empty-result-message"
    >
      <span class="gl-text-gray-500">{{ $options.i18n.noResultsMessage }}</span>
    </gl-dropdown-text>
  </gl-dropdown>
</template>

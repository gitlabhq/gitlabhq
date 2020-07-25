<script>
import {
  GlDeprecatedDropdown,
  GlDeprecatedDropdownItem,
  GlDeprecatedDropdownDivider,
  GlSearchBoxByType,
  GlIcon,
} from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { mapGetters } from 'vuex';

export default {
  name: 'CiEnvironmentsDropdown',
  components: {
    GlDeprecatedDropdown,
    GlDeprecatedDropdownItem,
    GlDeprecatedDropdownDivider,
    GlSearchBoxByType,
    GlIcon,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      searchTerm: this.value || '',
    };
  },
  computed: {
    ...mapGetters(['joinedEnvironments']),
    composedCreateButtonLabel() {
      return sprintf(__('Create wildcard: %{searchTerm}'), { searchTerm: this.searchTerm });
    },
    shouldRenderCreateButton() {
      return this.searchTerm && !this.joinedEnvironments.includes(this.searchTerm);
    },
    filteredResults() {
      const lowerCasedSearchTerm = this.searchTerm.toLowerCase();
      return this.joinedEnvironments.filter(resultString =>
        resultString.toLowerCase().includes(lowerCasedSearchTerm),
      );
    },
  },
  watch: {
    value(newVal) {
      this.searchTerm = newVal;
    },
  },
  methods: {
    selectEnvironment(selected) {
      this.$emit('selectEnvironment', selected);
      this.searchTerm = '';
    },
    createClicked() {
      this.$emit('createClicked', this.searchTerm);
      this.searchTerm = '';
    },
    isSelected(env) {
      return this.value === env;
    },
  },
};
</script>
<template>
  <gl-deprecated-dropdown :text="value">
    <gl-search-box-by-type v-model.trim="searchTerm" class="m-2" />
    <gl-deprecated-dropdown-item
      v-for="environment in filteredResults"
      :key="environment"
      @click="selectEnvironment(environment)"
    >
      <gl-icon
        :class="{ invisible: !isSelected(environment) }"
        name="mobile-issue-close"
        class="vertical-align-middle"
      />
      {{ environment }}
    </gl-deprecated-dropdown-item>
    <gl-deprecated-dropdown-item v-if="!filteredResults.length" ref="noMatchingResults">{{
      __('No matching results')
    }}</gl-deprecated-dropdown-item>
    <template v-if="shouldRenderCreateButton">
      <gl-deprecated-dropdown-divider />
      <gl-deprecated-dropdown-item @click="createClicked">
        {{ composedCreateButtonLabel }}
      </gl-deprecated-dropdown-item>
    </template>
  </gl-deprecated-dropdown>
</template>

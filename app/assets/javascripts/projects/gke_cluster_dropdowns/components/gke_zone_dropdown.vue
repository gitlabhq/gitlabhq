<script>
import { s__ } from '~/locale';
import { mapState, mapGetters, mapActions } from 'vuex';

import gcpDropdownMixin from './gcp_dropdown_mixin';

export default {
  name: 'GkeZoneDropdown',
  mixins: [gcpDropdownMixin],
  computed: {
    ...mapState(['selectedProject', 'selectedZone']),
    ...mapState({ items: 'zones' }),
    ...mapGetters(['hasProject']),
    isDisabled() {
      return !this.hasProject;
    },
    toggleText() {
      if (this.isLoading) {
        return s__('ClusterIntegration|Fetching zones');
      }

      if (this.selectedZone) {
        return this.selectedZone;
      }

      return !this.hasProject
        ? s__('ClusterIntegration|Select project to choose zone')
        : s__('ClusterIntegration|Select zone');
    },
    searchPlaceholderText() {
      return s__('ClusterIntegration|Search zones');
    },
    noSearchResultsText() {
      return s__('ClusterIntegration|No zones matched your search');
    },
  },
  watch: {
    selectedProject() {
      this.isLoading = true;

      this.getZones()
        .then(this.fetchSuccessHandler)
        .catch(this.fetchFailureHandler);
    },
  },
  methods: {
    ...mapActions(['getZones']),
    ...mapActions({ setItem: 'setZone' }),
  },
};
</script>

<template>
  <div
    class="js-gcp-zone-dropdown dropdown"
    :class="{ 'gl-show-field-errors': hasErrors }"
  >
    <dropdown-hidden-input
      :name="fieldName"
      :value="selectedZone"
    />
    <dropdown-button
      :class="{ 'gl-field-error-outline': hasErrors }"
      :is-disabled="isDisabled"
      :is-loading="isLoading"
      :toggle-text="toggleText"
    />
    <div class="dropdown-menu dropdown-select">
      <dropdown-search-input
        v-model="searchQuery"
        :placeholder-text="searchPlaceholderText"
      />
      <div class="dropdown-content">
        <ul>
          <li v-show="!results.length">
            <span class="menu-item">{{ noSearchResultsText }}</span>
          </li>
          <li
            v-for="result in results"
            :key="result.id"
          >
            <button @click.prevent="setItem(result.name)">
              {{ result.name }}
            </button>
          </li>
        </ul>
      </div>
      <div class="dropdown-loading">
        <loading-icon />
      </div>
    </div>
  </div>
</template>

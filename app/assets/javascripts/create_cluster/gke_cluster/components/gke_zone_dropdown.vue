<script>
import { mapState, mapActions } from 'vuex';
import { sprintf, s__ } from '~/locale';

import gkeDropdownMixin from './gke_dropdown_mixin';

export default {
  name: 'GkeZoneDropdown',
  mixins: [gkeDropdownMixin],
  computed: {
    ...mapState([
      'selectedProject',
      'selectedZone',
      'projects',
      'isValidatingProjectBilling',
      'projectHasBillingEnabled',
    ]),
    ...mapState({ items: 'zones' }),
    isDisabled() {
      return this.isLoading || this.isValidatingProjectBilling || !this.projectHasBillingEnabled;
    },
    toggleText() {
      if (this.isLoading) {
        return s__('ClusterIntegration|Fetching zones');
      }

      if (this.selectedZone) {
        return this.selectedZone;
      }

      return !this.projectHasBillingEnabled
        ? s__('ClusterIntegration|Select project to choose zone')
        : s__('ClusterIntegration|Select zone');
    },
    errorMessage() {
      return sprintf(
        s__('ClusterIntegration|An error occurred while trying to fetch project zones: %{error}'),
        { error: this.gapiError },
      );
    },
  },
  watch: {
    isValidatingProjectBilling(isValidating) {
      this.hasErrors = false;

      if (!isValidating && this.projectHasBillingEnabled) {
        this.isLoading = true;

        this.fetchZones().then(this.fetchSuccessHandler).catch(this.fetchFailureHandler);
      }
    },
  },
  methods: {
    ...mapActions(['fetchZones']),
    ...mapActions({ setItem: 'setZone' }),
  },
};
</script>

<template>
  <div>
    <div class="js-gcp-zone-dropdown dropdown">
      <dropdown-hidden-input :name="fieldName" :value="selectedZone" />
      <dropdown-button
        :class="{ 'border-danger': hasErrors }"
        :is-disabled="isDisabled"
        :is-loading="isLoading"
        :toggle-text="toggleText"
      />
      <div class="dropdown-menu dropdown-select">
        <dropdown-search-input
          v-model="searchQuery"
          :placeholder-text="s__('ClusterIntegration|Search zones')"
        />
        <div class="dropdown-content">
          <ul>
            <li v-show="!results.length">
              <span class="menu-item">
                {{ s__('ClusterIntegration|No zones matched your search') }}
              </span>
            </li>
            <li v-for="result in results" :key="result.id">
              <button type="button" @click.prevent="setItem(result.name)">{{ result.name }}</button>
            </li>
          </ul>
        </div>
        <div class="dropdown-loading"><gl-loading-icon size="sm" /></div>
      </div>
    </div>
    <span
      v-if="hasErrors"
      :class="{
        'text-danger': hasErrors,
        'text-muted': !hasErrors,
      }"
      class="form-text"
    >
      {{ errorMessage }}
    </span>
  </div>
</template>

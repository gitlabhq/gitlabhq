<script>
import { sprintf, s__ } from '~/locale';
import { mapState, mapGetters, mapActions } from 'vuex';

import gkeDropdownMixin from './gke_dropdown_mixin';

export default {
  name: 'GkeMachineTypeDropdown',
  mixins: [gkeDropdownMixin],
  computed: {
    ...mapState(['selectedProject', 'selectedZone', 'selectedMachineType']),
    ...mapState({ items: 'machineTypes' }),
    ...mapGetters(['hasProject', 'hasZone', 'hasMachineType']),
    allDropdownsSelected() {
      return this.hasProject && this.hasZone && this.hasMachineType;
    },
    isDisabled() {
      return !this.selectedProject || !this.selectedZone;
    },
    toggleText() {
      if (this.isLoading) {
        return s__('ClusterIntegration|Fetching machine types');
      }

      if (this.selectedMachineType) {
        return this.selectedMachineType;
      }

      if (!this.hasProject && !this.hasZone) {
        return s__('ClusterIntegration|Select project and zone to choose machine type');
      }

      return !this.hasZone
        ? s__('ClusterIntegration|Select zone to choose machine type')
        : s__('ClusterIntegration|Select machine type');
    },
    errorMessage() {
      return sprintf(
        s__(
          'ClusterIntegration|An error occured while trying to fetch zone machine types: %{error}',
        ),
        { error: this.gapiError },
      );
    },
  },
  watch: {
    selectedZone() {
      this.isLoading = true;

      this.getMachineTypes()
        .then(this.fetchSuccessHandler)
        .catch(this.fetchFailureHandler);
    },
    selectedMachineType() {
      this.enableSubmit();
    },
  },
  methods: {
    ...mapActions(['getMachineTypes']),
    ...mapActions({ setItem: 'setMachineType' }),
    enableSubmit() {
      if (this.allDropdownsSelected) {
        const submitButtonEl = document.querySelector('.js-gke-cluster-creation-submit');

        if (submitButtonEl) {
          submitButtonEl.removeAttribute('disabled');
        }
      }
    },
  },
};
</script>

<template>
  <div>
    <div
      class="js-gcp-machine-type-dropdown dropdown"
      :class="{ 'gl-show-field-errors': hasErrors }"
    >
      <dropdown-hidden-input
        :name="fieldName"
        :value="selectedMachineType"
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
          :placeholder-text="s__('ClusterIntegration|Search machine types')"
        />
        <div class="dropdown-content">
          <ul>
            <li v-show="!results.length">
              <span class="menu-item">
                {{ s__('ClusterIntegration|No machine types matched your search') }}
              </span>
            </li>
            <li
              v-for="result in results"
              :key="result.id"
            >
              <button
                type="button"
                @click.prevent="setItem(result.name)"
              >
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
    <span
      class="help-block"
      :class="{ 'gl-field-error': hasErrors }"
      v-if="hasErrors"
    >
      {{ errorMessage }}
    </span>
  </div>
</template>

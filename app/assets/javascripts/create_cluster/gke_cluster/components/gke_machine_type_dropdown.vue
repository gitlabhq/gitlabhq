<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { sprintf, s__ } from '~/locale';

import gkeDropdownMixin from './gke_dropdown_mixin';

export default {
  name: 'GkeMachineTypeDropdown',
  mixins: [gkeDropdownMixin],
  computed: {
    ...mapState([
      'isValidatingProjectBilling',
      'projectHasBillingEnabled',
      'selectedZone',
      'selectedMachineType',
    ]),
    ...mapState({ items: 'machineTypes' }),
    ...mapGetters(['hasZone', 'hasMachineType']),
    allDropdownsSelected() {
      return this.projectHasBillingEnabled && this.hasZone && this.hasMachineType;
    },
    isDisabled() {
      return (
        this.isLoading ||
        this.isValidatingProjectBilling ||
        !this.projectHasBillingEnabled ||
        !this.hasZone
      );
    },
    toggleText() {
      if (this.isLoading) {
        return s__('ClusterIntegration|Fetching machine types');
      }

      if (this.selectedMachineType) {
        return this.selectedMachineType;
      }

      if (!this.projectHasBillingEnabled && !this.hasZone) {
        return s__('ClusterIntegration|Select project and zone to choose machine type');
      }

      return !this.hasZone
        ? s__('ClusterIntegration|Select zone to choose machine type')
        : s__('ClusterIntegration|Select machine type');
    },
    errorMessage() {
      return sprintf(
        s__(
          'ClusterIntegration|An error occurred while trying to fetch zone machine types: %{error}',
        ),
        { error: this.gapiError },
      );
    },
  },
  watch: {
    selectedZone() {
      this.hasErrors = false;

      if (this.hasZone) {
        this.isLoading = true;

        this.fetchMachineTypes()
          .then(this.fetchSuccessHandler)
          .catch(this.fetchFailureHandler);
      }
    },
    selectedMachineType() {
      this.enableSubmit();
    },
  },
  methods: {
    ...mapActions(['fetchMachineTypes']),
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
    <div class="js-gcp-machine-type-dropdown dropdown">
      <dropdown-hidden-input :name="fieldName" :value="selectedMachineType" />
      <dropdown-button
        :class="{ 'border-danger': hasErrors }"
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
            <li v-for="result in results" :key="result.id">
              <button type="button" @click.prevent="setItem(result.name)">{{ result.name }}</button>
            </li>
          </ul>
        </div>
        <div class="dropdown-loading"><gl-loading-icon /></div>
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

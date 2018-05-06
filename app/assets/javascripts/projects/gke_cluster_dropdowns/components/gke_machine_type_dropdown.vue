<script>
import _ from 'underscore';
import { s__ } from '~/locale';
import { mapState, mapGetters, mapActions } from 'vuex';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import DropdownSearchInput from '~/vue_shared/components/dropdown/dropdown_search_input.vue';
import DropdownHiddenInput from '~/vue_shared/components/dropdown/dropdown_hidden_input.vue';

import eventHub from '../eventhub';
import store from '../stores';
import DropdownButton from './dropdown_button.vue';

export default {
  name: 'GkeMachineTypeDropdown',
  store,
  components: {
    LoadingIcon,
    DropdownButton,
    DropdownSearchInput,
    DropdownHiddenInput,
  },
  props: {
    fieldId: {
      type: String,
      required: true,
    },
    fieldName: {
      type: String,
      required: true,
    },
    defaultValue: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isLoading: false,
      hasErrors: false,
      searchQuery: '',
    };
  },
  computed: {
    ...mapState(['selectedProject', 'selectedZone', 'selectedMachineType']),
    ...mapState({ machineTypes: 'fetchedMachineTypes' }),
    ...mapGetters(['hasProject', 'hasZone', 'hasMachineType']),
    isDisabled() {
      return !this.selectedProject || !this.selectedZone;
    },
    results() {
      return this.machineTypes.filter(
        item => item.name.toLowerCase().indexOf(this.searchQuery) > -1,
      );
    },
    toggleText() {
      if (this.isLoading) {
        return s__('ClusterIntegration|Fetching machine types');
      }

      if (this.selectedMachineType) {
        return this.selectedMachineType;
      }

      if (!this.hasProject && !this.hasZone) {
        return s__('ClusterIntegration|Select project.and zone to choose machine type');
      }

      return !this.hasZone
        ? s__('ClusterIntegration|Select zone to choose machine type')
        : s__('ClusterIntegration|Select machine type');
    },
    searchPlaceholderText() {
      return s__('ClusterIntegration|Search machine types');
    },
  },
  created() {
    eventHub.$on('zoneSelected', this.fetchMachineTypes);
    eventHub.$on('machineTypeSelected', this.enableSubmit);
  },
  methods: {
    ...mapActions(['setMachineType', 'getMachineTypes']),
    fetchMachineTypes() {
      this.isLoading = true;

      this.getMachineTypes()
        .then(() => {
          if (this.defaultValue) {
            const machineTypeToSelect = _.find(
              this.machineTypes,
              item => item.name === this.defaultValue,
            );

            if (machineTypeToSelect) {
              this.setMachineType(machineTypeToSelect.name);
            }
          }

          this.isLoading = false;
          this.hasErrors = false;
        })
        .catch(() => {
          this.isLoading = false;
          this.hasErrors = true;
        });
    },
    enableSubmit() {
      if (this.hasProject && this.hasZone && this.hasMachineType) {
        document.querySelector('.js-gke-cluster-creation-submit').removeAttribute('disabled');
      }
    },
  },
};
</script>

<template>
  <div
    class="dropdown"
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
        :placeholder-text="searchPlaceholderText"
      />
      <div class="dropdown-content">
        <ul>
          <li
            v-for="result in results"
            :key="result.id"
          >
            <a
              href="#"
              @click.prevent="setMachineType(result.name)"
            >{{ result.name }}</a>
          </li>
        </ul>
      </div>
      <div class="dropdown-loading">
        <loading-icon />
      </div>
    </div>
  </div>
</template>

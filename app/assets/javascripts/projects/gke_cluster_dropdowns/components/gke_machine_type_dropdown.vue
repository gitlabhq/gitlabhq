<script>
import _ from 'underscore';
import Flash from '~/flash';
import { s__, sprintf } from '~/locale';
import { mapState, mapGetters, mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
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
    Icon,
    LoadingIcon,
    DropdownButton,
    DropdownSearchInput,
    DropdownHiddenInput,
  },
  props: {
    service: {
      type: Object,
      required: true,
    },
    fieldId: {
      type: String,
      required: true,
    },
    fieldName: {
      type: String,
      required: true,
    },
    inputValue: {
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
      items: [],
    };
  },
  computed: {
    ...mapState(['selectedProject', 'selectedZone', 'selectedMachineType']),
    ...mapGetters(['hasProject', 'hasZone']),
    isDisabled() {
      return !this.selectedProject || !this.selectedZone;
    },
    searchResults() {
      return this.items.filter(item => item.name.toLowerCase().indexOf(this.searchQuery) > -1);
    },
    toggleText() {
      if (this.isLoading) {
        return s__('ClusterIntegration|Fetching machine types');
      }

      if (this.selectedMachineType) {
        return this.selectedMachineType;
      }

      if (!this.hasProject && !this.hasZone) {
        return s__('ClusterIntegration|Select project and zone to choose machine type.');
      }

      return this.hasZone
        ? s__('ClusterIntegration|Select machine type')
        : s__('ClusterIntegration|Select zone to choose machine type');
    },
    placeholderText() {
      return s__('ClusterIntegration|Search machine types');
    },
  },
  created() {
    eventHub.$on('zoneSelected', this.fetchItems);
    eventHub.$on('machineTypeSelected', this.enableSubmit);
  },
  methods: {
    ...mapActions(['setMachineType']),
    fetchItems() {
      this.isLoading = true;
      const request = this.service.machineTypes.list({
        project: this.selectedProject.projectId,
        zone: this.selectedZone,
      });

      return request.then(
        resp => {
          let machineTypeToSelect;
          this.items = resp.result.items;

          if (this.inputValue) {
            machineTypeToSelect = _.find(this.items, item => item.name === this.inputValue);
            this.setMachineType(machineTypeToSelect.name);
          }

          this.isLoading = false;
          this.hasErrors = false;
        },
        () => {
          this.isLoading = false;
          this.hasErrors = true;

          if (resp.result.error) {
            Flash(
              sprintf(
                'ClusterIntegration|An error occured while trying to fetch zone machine types: %{error}',
                { error: resp.result.error.message },
              ),
            );
          }
        },
        this,
      );
    },
    enableSubmit() {
      document.querySelector('.js-gke-cluster-creation-submit').removeAttribute('disabled');
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
        :placeholder-text="placeholderText"
      />
      <div class="dropdown-content">
        <ul>
          <li
            v-for="result in searchResults"
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

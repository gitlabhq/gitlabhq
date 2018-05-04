<script>
import Flash from '~/flash';
import { s__ } from '~/locale';
import { mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import DropdownSearchInput from '~/vue_shared/components/dropdown/dropdown_search_input.vue';
import DropdownHiddenInput from '~/vue_shared/components/dropdown/dropdown_hidden_input.vue';

import eventHub from '../eventhub';
import store from '../stores';
import DropdownButton from './dropdown_button.vue';
// TODO: Fall back to default us-central1-a or first option

export default {
  name: 'GkeZoneDropdown',
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
  },
  data() {
    return {
      isLoading: false,
      hasErrors: false,
      searchQuery: '',
      selectedItem: '',
      items: [],
    };
  },
  computed: {
    isDisabled() {
      return this.$store.state.selectedProject.projectId.length === 0;
    },
    results() {
      return this.items.filter(item => item.name.toLowerCase().indexOf(this.searchQuery) > -1);
    },
    toggleText() {
      if (this.$store.state.selectedZone) {
        return this.$store.state.selectedZone;
      }

      if (this.isLoading) {
        return s__('ClusterIntegration|Fetching zones');
      }

      return this.$store.state.selectedProject
        ? s__('ClusterIntegration|Select zone')
        : s__('ClusterIntegration|Select project to choose zone');
    },
    placeholderText() {
      return s__('ClusterIntegration|Search zones');
    },
  },
  created() {
    eventHub.$on('projectSelected', this.fetchItems);
  },
  methods: {
    ...mapActions(['setZone']),
    fetchItems() {
      this.isLoading = true;
      const request = this.service.zones.list({
        project: this.$store.state.selectedProject.projectId,
      });

      return request.then(
        resp => {
          this.items = resp.result.items;

          // Cause error
          // this.items = data;

          // Single state
          // this.items = [
          //   {
          //     create_time: '2018-01-16T15:55:02.992Z',
          //     lifecycle_state: 'ACTIVE',
          //     name: 'NaturalInterface',
          //     item_id: 'naturalinterface-192315',
          //     item_number: 840816084083,
          //   },
          // ];

          if (this.items.length === 1) {
            this.isDisabled = true;
            this.setZone(this.items[0].name);
          }

          this.isLoading = false;
        },
        resp => {
          this.isLoading = false;
          this.hasErrors = true;

          if (resp.result.error) {
            Flash(
              `${s__('ClusterIntegration|An error occured while trying to fetch project zones:')} ${
                resp.result.error.message
              }`,
            );
          }
        },
        this,
      );
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
      :value="$store.state.selectedZone"
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
            v-for="result in results"
            :key="result.id"
          >
            <a
              href="#"
              @click.prevent="setZone(result.name)"
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

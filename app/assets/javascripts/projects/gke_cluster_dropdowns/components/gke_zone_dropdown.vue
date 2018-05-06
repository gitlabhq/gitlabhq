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
    ...mapState(['selectedProject', 'selectedZone']),
    ...mapGetters(['hasProject']),
    isDisabled() {
      return !this.hasProject;
    },
    searchResults() {
      return this.items.filter(item => item.name.toLowerCase().indexOf(this.searchQuery) > -1);
    },
    toggleText() {
      if (this.isLoading) {
        return s__('ClusterIntegration|Fetching zones');
      }

      if (this.selectedZone) {
        return this.selectedZone;
      }

      return this.$store.state.selectedProject.projectId.length
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
        project: this.selectedProject.projectId,
      });

      return request.then(
        resp => {
          let zoneToSelect;
          this.items = resp.result.items;

          if (this.inputValue) {
            zoneToSelect = _.find(this.items, item => item.name === this.inputValue);
            this.setZone(zoneToSelect.name);
          }

          this.isLoading = false;
          this.hasErrors = false;
        },
        resp => {
          this.isLoading = false;
          this.hasErrors = true;

          if (resp.result.error) {
            Flash(
              sprintf(
                'ClusterIntegration|An error occured while trying to fetch project zones: %{error}',
                { error: resp.result.error.message },
              ),
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

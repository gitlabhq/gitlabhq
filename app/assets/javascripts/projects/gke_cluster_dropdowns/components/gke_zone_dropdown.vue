<script>
import _ from 'underscore';
import { s__ } from '~/locale';
import { mapState, mapGetters, mapActions } from 'vuex';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import DropdownSearchInput from '~/vue_shared/components/dropdown/dropdown_search_input.vue';
import DropdownHiddenInput from '~/vue_shared/components/dropdown/dropdown_hidden_input.vue';
import DropdownButton from '~/vue_shared/components/dropdown/dropdown_button.vue';

import eventHub from '../eventhub';
import store from '../stores';

export default {
  name: 'GkeZoneDropdown',
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
    ...mapState(['selectedProject', 'selectedZone']),
    ...mapState({ zones: 'fetchedZones' }),
    ...mapGetters(['hasProject']),
    isDisabled() {
      return !this.hasProject;
    },
    results() {
      return this.zones.filter(item => item.name.toLowerCase().indexOf(this.searchQuery) > -1);
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
  },
  created() {
    eventHub.$on('projectSelected', this.fetchZones);
  },
  methods: {
    ...mapActions(['setZone', 'getZones']),
    fetchZones() {
      this.isLoading = true;

      this.getZones()
        .then(() => {
          if (this.defaultValue) {
            const zoneToSelect = _.find(this.zones, item => item.name === this.defaultValue);

            if (zoneToSelect) {
              this.setZone(zoneToSelect.name);
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

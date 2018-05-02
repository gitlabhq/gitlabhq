<script>
import _ from 'underscore';
import Flash from '~/flash';
import { s__, sprintf } from '~/locale';
import { mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import DropdownSearchInput from '~/vue_shared/components/dropdown/dropdown_search_input.vue';
import DropdownHiddenInput from '~/vue_shared/components/dropdown/dropdown_hidden_input.vue';

import store from '../stores';
import DropdownButton from './dropdown_button.vue';
// TODO: Consolidate dropdown code
// TODO: Account for invalid project settings/errors (project returns error when retrieving zones)

export default {
  name: 'GkeProjectIdDropdown',
  store,
  components: {
    Icon,
    LoadingIcon,
    DropdownButton,
    DropdownSearchInput,
    DropdownHiddenInput,
  },
  props: {
    docsUrl: {
      type: String,
      required: true,
    },
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
      isDisabled: false,
      isLoading: true,
      hasErrors: false,
      searchQuery: '',
      selectedItem: '',
      items: [],
    };
  },
  computed: {
    results() {
      return this.items.filter(item => item.name.toLowerCase().indexOf(this.searchQuery) > -1);
    },
    toggleText() {
      if (this.$store.state.selectedProject) {
        return this.$store.state.selectedProject;
      }

      return this.isLoading
        ? s__('ClusterIntegration|Fetching projects')
        : s__('ClusterIntegration|Select project');
    },
    placeholderText() {
      return s__('ClusterIntegration|Search projects');
    },
    helpText() {
      let message;
      if (this.hasErrors) {
        message =
          'ClusterIntegration|We were unable to fetch any projects. Ensure that you have a project on %{docsLinkStart}Google Cloud Platform%{docsLinkEnd}.';
      }

      message = this.items.length
        ? 'ClusterIntegration|To use a new project, first create one on %{docsLinkStart}Google Cloud Platform%{docsLinkEnd}.'
        : 'ClusterIntegration|To create a cluster, first create a project on %{docsLinkStart}Google Cloud Platform%{docsLinkEnd}.';

      return sprintf(
        s__(message),
        {
          docsLinkEnd: '&nbsp;<i class="fa fa-external-link" aria-hidden="true"></i></a>',
          docsLinkStart: `<a href="${_.escape(
            this.docsUrl,
          )}" target="_blank" rel="noopener noreferrer">`,
        },
        false,
      );
    },
  },
  created() {
    this.fetchItems();
  },
  methods: {
    ...mapActions(['setProject']),
    fetchItems() {
      const request = this.service.projects.list();

      return request.then(
        resp => {
          this.items = resp.result.projects;

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
            this.setProject(this.items[0].name);
          }

          this.isLoading = false;
        },
        resp => {
          this.isLoading = false;
          this.hasErrors = true;

          if (resp.result.error) {
            Flash(
              `${s__('ClusterIntegration|An error occured while trying to fetch your projects:')} ${
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
  <div>
    <div
      class="dropdown"
      :class="{ 'gl-show-field-errors': hasErrors }"
    >
      <dropdown-hidden-input
        :name="fieldName"
        :value="$store.state.selectedProject"
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
              :key="result.project_number"
            >
              <a
                href="#"
                @click.prevent="setProject(result.name)"
              >{{ result.name }}</a>
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
      :class="{ 'gl-field-error-message': hasErrors }"
      v-html="helpText"
    ></span>
  </div>
</template>

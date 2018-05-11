<script>
import _ from 'underscore';
import { s__, sprintf } from '~/locale';
import { mapState, mapGetters, mapActions } from 'vuex';

import gkeDropdownMixin from './gke_dropdown_mixin';

export default {
  name: 'GkeProjectIdDropdown',
  mixins: [gkeDropdownMixin],
  props: {
    docsUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      searchPlaceholderText: s__('ClusterIntegration|Search projects'),
      noSearchResultsText: s__('ClusterIntegration|No projects matched your search'),
    };
  },
  computed: {
    ...mapState(['selectedProject']),
    ...mapState({ items: 'projects' }),
    ...mapGetters(['hasProject']),
    hasOneProject() {
      return this.items.length === 1;
    },
    isDisabled() {
      return this.items.length < 2;
    },
    toggleText() {
      if (this.isLoading) {
        return s__('ClusterIntegration|Fetching projects');
      }

      if (this.hasProject) {
        return this.selectedProject.name;
      }

      return !this.items.length
        ? s__('ClusterIntegration|No projects found')
        : s__('ClusterIntegration|Select project');
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
    this.isLoading = true;

    this.getProjects()
      .then(this.fetchSuccessHandler)
      .catch(this.fetchFailureHandler);
  },
  methods: {
    ...mapActions(['getProjects']),
    ...mapActions({ setItem: 'setProject' }),
    fetchSuccessHandler() {
      if (this.defaultValue) {
        const projectToSelect = _.find(this.items, item => item.projectId === this.defaultValue);

        if (projectToSelect) {
          this.setItem(projectToSelect);
        }
      } else if (this.items.length === 1) {
        this.setItem(this.items[0]);
      }

      this.isLoading = false;
      this.hasErrors = false;
    },
  },
};
</script>

<template>
  <div>
    <div
      class="js-gcp-project-id-dropdown dropdown"
      :class="{ 'gl-show-field-errors': hasErrors }"
    >
      <dropdown-hidden-input
        :name="fieldName"
        :value="selectedProject.projectId"
      />
      <dropdown-button
        :class="{
          'gl-field-error-outline': hasErrors,
          'read-only': hasOneProject
        }"
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
              :key="result.project_number"
            >
              <button @click.prevent="setItem(result)">
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
      :class="{ 'gl-field-error-message': hasErrors }"
      v-html="helpText"
    ></span>
  </div>
</template>

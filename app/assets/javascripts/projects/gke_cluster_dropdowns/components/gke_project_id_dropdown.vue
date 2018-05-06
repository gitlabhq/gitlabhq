<script>
import _ from 'underscore';
import { s__, sprintf } from '~/locale';
import { mapState, mapGetters, mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import DropdownSearchInput from '~/vue_shared/components/dropdown/dropdown_search_input.vue';
import DropdownHiddenInput from '~/vue_shared/components/dropdown/dropdown_hidden_input.vue';

import store from '../stores';
import DropdownButton from './dropdown_button.vue';

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
      isLoading: true,
      hasErrors: false,
      searchQuery: '',
    };
  },
  computed: {
    ...mapState(['selectedProject']),
    ...mapState({ projects: 'fetchedProjects' }),
    ...mapGetters(['hasProject']),
    hasOneProject() {
      return this.projects.length === 1;
    },
    isDisabled() {
      return this.projects.length < 2;
    },
    searchResults() {
      return this.projects.filter(item => item.name.toLowerCase().indexOf(this.searchQuery) > -1);
    },
    toggleText() {
      if (this.isLoading) {
        return s__('ClusterIntegration|Fetching projects');
      }

      if (this.hasProject) {
        return this.selectedProject.name;
      }

      return this.projects.length
        ? s__('ClusterIntegration|Select project')
        : s__('ClusterIntegration|No projects found');
    },
    searchPlaceholderText() {
      return s__('ClusterIntegration|Search projects');
    },
    helpText() {
      let message;
      if (this.hasErrors) {
        message =
          'ClusterIntegration|We were unable to fetch any projects. Ensure that you have a project on %{docsLinkStart}Google Cloud Platform%{docsLinkEnd}.';
      }

      message = this.projects.length
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
    this.fetchProjects();
  },
  methods: {
    ...mapActions(['setProject', 'getProjects']),
    fetchProjects() {
      this.getProjects()
        .then(() => {
          if (this.defaultValue) {
            const projectToSelect = _.find(
              this.projects,
              item => item.projectId === this.defaultValue,
            );

            if (projectToSelect) {
              this.setProject(projectToSelect);
            }
          } else if (this.projects.length === 1) {
            this.setProject(this.projects[0]);
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
  <div>
    <div
      class="dropdown"
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
            <li
              v-for="result in searchResults"
              :key="result.project_number"
            >
              <a
                href="#"
                @click.prevent="setProject(result)"
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

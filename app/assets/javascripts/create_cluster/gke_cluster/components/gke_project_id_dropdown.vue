<script>
import { GlSprintf, GlLink, GlIcon } from '@gitlab/ui';
import { mapState, mapGetters, mapActions } from 'vuex';
import { s__ } from '~/locale';

import gkeDropdownMixin from './gke_dropdown_mixin';

export default {
  name: 'GkeProjectIdDropdown',
  components: {
    GlSprintf,
    GlLink,
    GlIcon,
  },
  mixins: [gkeDropdownMixin],
  props: {
    docsUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['selectedProject', 'isValidatingProjectBilling', 'projectHasBillingEnabled']),
    ...mapState({ items: 'projects' }),
    ...mapGetters(['hasProject']),
    hasOneProject() {
      return this.items && this.items.length === 1;
    },
    isDisabled() {
      return (
        this.isLoading || this.isValidatingProjectBilling || (this.items && this.items.length < 2)
      );
    },
    toggleText() {
      if (this.isValidatingProjectBilling) {
        return s__('ClusterIntegration|Validating project billing status');
      }

      if (this.isLoading) {
        return s__('ClusterIntegration|Fetching projects');
      }

      if (this.hasProject) {
        return this.selectedProject.name;
      }

      if (!this.items) {
        return s__('ClusterIntegration|No projects found');
      }

      return s__('ClusterIntegration|Select project');
    },
    helpText() {
      if (this.hasErrors) {
        return this.errorMessage;
      }

      if (!this.items) {
        return s__(
          'ClusterIntegration|We were unable to fetch any projects. Ensure that you have a project on %{docsLinkStart}Google Cloud Platform%{docsLinkEnd}.',
        );
      }

      return this.items.length
        ? s__(
            'ClusterIntegration|To use a new project, first create one on %{docsLinkStart}Google Cloud Platform%{docsLinkEnd}.',
          )
        : s__(
            'ClusterIntegration|To create a cluster, first create a project on %{docsLinkStart}Google Cloud Platform%{docsLinkEnd}.',
          );
    },
    errorMessage() {
      if (!this.projectHasBillingEnabled) {
        if (this.gapiError) {
          return s__(
            'ClusterIntegration|We could not verify that one of your projects on GCP has billing enabled. Please try again.',
          );
        }

        return s__(
          'ClusterIntegration|This project does not have billing enabled. To create a cluster, %{linkToBillingStart}enable billing%{linkToBillingEnd} and try again.',
        );
      }

      return s__(
        'ClusterIntegration|An error occurred while trying to fetch your projects: %{error}',
      );
    },
  },
  watch: {
    selectedProject() {
      this.setIsValidatingProjectBilling(true);

      this.validateProjectBilling()
        .then(this.validateProjectBillingSuccessHandler)
        .catch(this.validateProjectBillingFailureHandler);
    },
  },
  created() {
    this.isLoading = true;

    this.fetchProjects().then(this.fetchSuccessHandler).catch(this.fetchFailureHandler);
  },
  methods: {
    ...mapActions(['fetchProjects', 'setIsValidatingProjectBilling', 'validateProjectBilling']),
    ...mapActions({ setItem: 'setProject' }),
    fetchSuccessHandler() {
      if (this.defaultValue) {
        const projectToSelect = this.items.find((item) => item.projectId === this.defaultValue);

        if (projectToSelect) {
          this.setItem(projectToSelect);
        }
      } else if (this.items.length === 1) {
        this.setItem(this.items[0]);
      }

      this.isLoading = false;
      this.hasErrors = false;
    },
    validateProjectBillingSuccessHandler() {
      this.hasErrors = !this.projectHasBillingEnabled;
    },
    validateProjectBillingFailureHandler(resp) {
      this.hasErrors = true;

      this.gapiError = resp.result ? resp.result.error.message : resp;
    },
  },
};
</script>

<template>
  <div>
    <div class="js-gcp-project-id-dropdown dropdown">
      <dropdown-hidden-input :name="fieldName" :value="selectedProject.projectId" />
      <dropdown-button
        :class="{
          'border-danger': hasErrors,
          'read-only': hasOneProject,
        }"
        :is-disabled="isDisabled"
        :is-loading="isLoading"
        :toggle-text="toggleText"
      />
      <div class="dropdown-menu dropdown-select">
        <dropdown-search-input
          v-model="searchQuery"
          :placeholder-text="s__('ClusterIntegration|Search projects')"
        />
        <div class="dropdown-content">
          <ul>
            <li v-show="!results.length">
              <span class="menu-item">
                {{ s__('ClusterIntegration|No projects matched your search') }}
              </span>
            </li>
            <li v-for="result in results" :key="result.project_number">
              <button type="button" @click.prevent="setItem(result)">{{ result.name }}</button>
            </li>
          </ul>
        </div>
        <div class="dropdown-loading"><gl-loading-icon size="sm" /></div>
      </div>
    </div>
    <span
      :class="{
        'text-danger': hasErrors,
        'text-muted': !hasErrors,
      }"
      class="form-text"
    >
      <gl-sprintf :message="helpText">
        <template #linkToBilling="{ content }">
          <gl-link
            :href="'https://console.cloud.google.com/freetrial?utm_campaign=2018_cpanel&utm_source=gitlab&utm_medium=referral'"
            target="_blank"
            >{{ content }} <gl-icon name="external-link"
          /></gl-link>
        </template>

        <template #docsLink="{ content }">
          <gl-link :href="docsUrl" target="_blank"
            >{{ content }} <gl-icon name="external-link"
          /></gl-link>
        </template>

        <template #error>
          {{ gapiError }}
        </template>
      </gl-sprintf>
    </span>
  </div>
</template>

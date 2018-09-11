<script>
import { mapState } from 'vuex';
import $ from 'jquery';
import { n__, s__ } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon.vue';

export default {
  name: 'SummaryReport',
  components: {
    CiIcon,
  },
  computed: {
    ...mapState(['sast', 'dependencyScanning', 'dast', 'sastContainer']),
    sastLink() {
      return this.link(this.sast.newIssues.length);
    },
    dependencyScanningLink() {
      return this.link(this.dependencyScanning.newIssues.length);
    },
    dastLink() {
      return this.link(this.dast.newIssues.length);
    },
    sastContainerLink() {
      return this.link(this.sastContainer.newIssues.length);
    },
    sastIcon() {
      return this.statusIcon(this.hasSastError, this.sast.newIssues.length);
    },
    dependencyScanningIcon() {
      return this.statusIcon(
        this.hasDependencyScanningError,
        this.dependencyScanning.newIssues.length,
      );
    },
    dastIcon() {
      return this.statusIcon(this.hasDastError, this.dast.newIssues.length);
    },
    sastContainerIcon() {
      return this.statusIcon(this.hasSastContainerError, this.sastContainer.newIssues.length);
    },
    hasSast() {
      return this.sast.paths.head !== null;
    },
    hasDependencyScanning() {
      return this.dependencyScanning.paths.head !== null;
    },
    hasDast() {
      return this.dast.paths.head !== null;
    },
    hasSastContainer() {
      return this.sastContainer.paths.head !== null;
    },
    isLoadingSast() {
      return this.sast.isLoading;
    },
    isLoadingDependencyScanning() {
      return this.dependencyScanning.isLoading;
    },
    isLoadingDast() {
      return this.dast.isLoading;
    },
    isLoadingSastContainer() {
      return this.sastContainer.isLoading;
    },
    hasSastError() {
      return this.sast.hasError;
    },
    hasDependencyScanningError() {
      return this.dependencyScanning.hasError;
    },
    hasDastError() {
      return this.dast.hasError;
    },
    hasSastContainerError() {
      return this.sastContainer.hasError;
    },
  },
  methods: {
    openTab() {
      // This opens a tab outside of this Vue application
      // It opens the securty report tab in the pipelines page and updates the URL
      // This is needed because the tabs are built in haml+jquery
      $('.pipelines-tabs a[data-action="security"]').tab('show');
    },
    link(issuesCount = 0) {
      if (issuesCount > 0) {
        return n__('%d vulnerability', '%d vulnerabilities', issuesCount);
      }
      return s__('ciReport|no vulnerabilities');
    },
    statusIcon(failed = true, issuesCount = 0) {
      if (issuesCount > 0 || failed) {
        return {
          group: 'warning',
          icon: 'status_warning',
        };
      }
      return {
        group: 'success',
        icon: 'status_success',
      };
    },
  },
};
</script>
<template>
  <div>
    <div
      v-if="hasSast"
      class="well-segment flex js-sast-summary"
    >
      <gl-loading-icon
        v-if="isLoadingSast"
      />

      <ci-icon
        v-else
        :status="sastIcon"
        class="flex flex-align-self-center"
      />

      <span
        class="prepend-left-10 flex flex-align-self-center"
      >
        <template v-if="hasSastError">
          {{ s__('ciReport|SAST resulted in error while loading results') }}
        </template>
        <template v-else-if="isLoadingSast">
          {{ s__('ciReport|SAST is loading') }}
        </template>
        <template v-else>
          {{ s__('ciReport|SAST detected') }}
          <button
            type="button"
            class="btn-link btn-blank prepend-left-5"
            @click="openTab"
          >
            {{ sastLink }}
          </button>
        </template>
      </span>
    </div>
    <div
      v-if="hasDependencyScanning"
      class="well-segment flex js-dss-summary"
    >
      <gl-loading-icon
        v-if="isLoadingDependencyScanning"
      />
      <ci-icon
        v-else
        :status="dependencyScanningIcon"
        class="flex flex-align-self-center"
      />

      <span
        class="prepend-left-10 flex flex-align-self-center"
      >
        <template v-if="hasDependencyScanningError">
          {{ s__('ciReport|Dependency scanning resulted in error while loading results') }}
        </template>
        <template v-else-if="isLoadingDependencyScanning">
          {{ s__('ciReport|Dependency scanning is loading') }}
        </template>
        <template v-else>
          {{ s__('ciReport|Dependency scanning detected') }}
          <button
            type="button"
            class="btn-link btn-blank prepend-left-5"
            @click="openTab"
          >
            {{ dependencyScanningLink }}
          </button>
        </template>
      </span>
    </div>
    <div
      v-if="hasSastContainer"
      class="well-segment flex js-sast-container-summary"
    >
      <gl-loading-icon
        v-if="isLoadingSastContainer"
      />
      <ci-icon
        v-else
        :status="sastContainerIcon"
        class="flex flex-align-self-center"
      />

      <span
        class="prepend-left-10 flex flex-align-self-center"
      >
        <template v-if="hasSastContainerError">
          {{ s__('ciReport|Container scanning resulted in error while loading results') }}
        </template>
        <template v-else-if="isLoadingSastContainer">
          {{ s__('ciReport|Container scanning is loading') }}
        </template>
        <template v-else>
          {{ s__('ciReport|Container scanning detected') }}
          <button
            type="button"
            class="btn-link btn-blank prepend-left-5"
            @click="openTab"
          >
            {{ sastContainerLink }}
          </button>
        </template>
      </span>
    </div>
    <div
      v-if="hasDast"
      class="well-segment flex js-dast-summary"
    >
      <gl-loading-icon
        v-if="isLoadingDast"
      />
      <ci-icon
        v-else
        :status="dastIcon"
        class="flex flex-align-self-center"
      />

      <span
        class="prepend-left-10 flex flex-align-self-center"
      >
        <template v-if="hasDastError">
          {{ s__('ciReport|DAST resulted in error while loading results') }}
        </template>
        <template v-else-if="isLoadingDast">
          {{ s__('ciReport|DAST is loading') }}
        </template>
        <template v-else>
          {{ s__('ciReport|DAST detected') }}
          <button
            type="button"
            class="btn-link btn-blank prepend-left-5"
            @click="openTab"
          >
            {{ dastLink }}
          </button>
        </template>
      </span>
    </div>
  </div>
</template>

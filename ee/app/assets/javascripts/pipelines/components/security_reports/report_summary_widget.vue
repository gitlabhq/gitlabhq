<script>
import { mapState } from 'vuex';
import $ from 'jquery';
import { n__, s__ } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';

export default {
  name: 'SummaryReport',
  components: {
    CiIcon,
    LoadingIcon,
  },
  computed: {
    ...mapState(['sast', 'dependencyScanning']),
    sastLink() {
      return this.link(this.sast.newIssues.length);
    },
    dependencyScanningLink() {
      return this.link(this.dependencyScanning.newIssues.length);
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
    hasSast() {
      return this.sast.paths.head !== null;
    },
    hasDependencyScanning() {
      return this.dependencyScanning.paths.head !== null;
    },
    isLoadingSast() {
      return this.sast.isLoading;
    },
    isLoadingDependencyScanning() {
      return this.dependencyScanning.isLoading;
    },
    hasSastError() {
      return this.sast.hasError;
    },
    hasDependencyScanningError() {
      return this.dependencyScanning.hasError;
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
      class="well-segment flex js-sast-summary"
      v-if="hasSast"
    >
      <loading-icon
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
      class="well-segment flex js-dss-summary"
      v-if="hasDependencyScanning"
    >
      <loading-icon
        v-if="dependencyScanning.isLoading"
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
  </div>
</template>

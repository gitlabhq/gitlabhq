<script>
  import $ from 'jquery';
  import { n__, s__ } from '~/locale';
  import CiIcon from '~/vue_shared/components/ci_icon.vue';

  export default {
    name: 'SummaryReport',
    components: {
      CiIcon,
    },
    props: {
      sastIssues: {
        type: Number,
        required: false,
        default: 0,
      },
      dependencyScanningIssues: {
        type: Number,
        required: false,
        default: 0,
      },
      hasDependencyScanning: {
        type: Boolean,
        required: false,
        default: false,
      },
      hasSast: {
        type: Boolean,
        required: false,
        default: false,
      },
    },
    computed: {
      sastLink() {
        return this.link(this.sastIssues);
      },
      dependencyScanningLink() {
        return this.link(this.dependencyScanningIssues);
      },
      sastIcon() {
        return this.statusIcon(this.sastIssues);
      },
      dependencyScanningIcon() {
        return this.statusIcon(this.dependencyScanningIssues);
      },
    },
    methods: {
      openTab() {
        // This opens a tab outside of this Vue application
        // It opens the securty report tab in the pipelines page and updates the URL
        // This is needed because the tabs are built in haml+jquery
        $('.pipelines-tabs a[data-action="security"]').tab('show');
      },
      link(issues) {
        if (issues > 0) {
          return n__(
            '%d vulnerability',
            '%d vulnerabilities',
            issues,
          );
        }
        return s__('ciReport|no vulnerabilities');
      },
      statusIcon(issues) {
        if (issues > 0) {
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
      <ci-icon
        :status="sastIcon"
        class="flex flex-align-self-center"
      />

      <span
        class="prepend-left-10 flex flex-align-self-center"
      >
        {{ s__('ciReport|SAST detected') }}
        <button
          type="button"
          class="btn-link btn-blank prepend-left-5"
          @click="openTab"
        >
          {{ sastLink }}
        </button>
      </span>
    </div>
    <div
      class="well-segment flex js-dss-summary"
      v-if="hasDependencyScanning"
    >
      <ci-icon
        :status="dependencyScanningIcon"
        class="flex flex-align-self-center"
      />

      <span
        class="prepend-left-10 flex flex-align-self-center"
      >
        {{ s__('ciReport|Dependency scanning detected') }}
        <button
          type="button"
          class="btn-link btn-blank prepend-left-5"
          @click="openTab"
        >
          {{ dependencyScanningLink }}
        </button>
      </span>
    </div>
  </div>
</template>

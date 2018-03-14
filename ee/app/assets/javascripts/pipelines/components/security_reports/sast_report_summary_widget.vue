<script>
  import $ from 'jquery';
  import { n__, s__ } from '~/locale';
  import ciIcon from '~/vue_shared/components/ci_icon.vue';

  export default {
    name: 'SastSummaryReport',
    components: {
      ciIcon,
    },
    props: {
      unresolvedIssues: {
        type: Array,
        required: false,
        default: () => ([]),
      },
    },
    computed: {
      sastText() {
        if (this.unresolvedIssues.length) {
          return s__('ciReport|SAST degraded on');
        }
        return s__('ciReport|SAST detected');
      },
      sastLink() {
        if (this.unresolvedIssues.length) {
          return n__(
            '%d security vulnerability',
            '%d security vulnerabilities',
            this.unresolvedIssues.length,
          );
        }
        return s__('ciReport|no security vulnerabilities');
      },
      statusIcon() {
        if (this.unresolvedIssues.length) {
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
    methods: {
      openTab() {
        // This opens a tab outside of this Vue application
        // It opens the securty report tab in the pipelines page and updates the URL
        // This is needed because the tabs are built in haml+jquery
        $('.pipelines-tabs a[data-action="security"]').tab('show');
      },
    },
  };
</script>
<template>
  <div class="well-segment flex">
    <ci-icon
      :status="statusIcon"
      class="flex flex-align-self-center"
    />

    <span
      class="prepend-left-10 flex flex-align-self-center"
    >
      {{ sastText }}
      <button
        type="button"
        class="btn-link btn-blank prepend-left-5"
        @click="openTab"
      >
        {{ sastLink }}
      </button>
    </span>
  </div>
</template>

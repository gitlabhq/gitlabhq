<script>
  import LoadingIcon from '~/vue_shared/components/loading_icon.vue';

  export default {
    name: 'ReportSummary',
    components: {
      LoadingIcon,
    },
    props: {
      // security | codequality | performance | docker
      type: {
        type: String,
        required: true,
      },
      // loading | success | error
      status: {
        type: String,
        required: true,
      },
      loadingText: {
        type: String,
        required: true,
      },
      errorText: {
        type: String,
        required: true,
      },
      successText: {
        type: String,
        required: true,
      },
      hasCollapseButton: {
        type: Boolean,
        required: false,
        default: false,
      },
    },

    computed: {
      isLoading() {
        return this.status === 'loading';
      },
      loadingFailed() {
        return this.status === 'error';
      },
      isSuccess() {
        return this.status === 'success';
      },
      statusIconName() {
        if (this.loadingFailed || this.unresolvedIssues.length) {
          return 'warning';
        }
        return 'success';
      },
    },

    methods: {
      toggleCollapsed() {
        this.$emit('toggleCollapsed');
      },
    },
  };
</script>
<template>
  <div>
    <div
      v-if="isLoading"
      class="media"
    >
      <div
        class="mr-widget-icon"
      >
        <loading-icon />
      </div>
      <div
        class="media-body"
      >
        {{ loadingText }}
      </div>
    </div>

    <div
      v-else-if="isSuccess"
      class="media"
    >
      <status-icon
        :status="statusIconName"
      />

      <div
        class="media-body space-children"
      >
        <span
          class="js-code-text"
        >
          {{ successText }}
        </span>

        <button
          type="button"
          class="btn pull-right btn-sm"
          v-if="hasCollapseButton"
          @click="toggleCollapsed"
        >
          {{ collapseText }}
        </button>
      </div>
    </div>
  </div>

</template>

<script>
  import ciIcon from '../../vue_shared/components/ci_icon.vue';

  export default {
    components: {
      ciIcon,
    },
    props: {
      status: {
        type: String,
        required: true,
      },
      showDisabledButton: {
        type: Boolean,
        required: false,
        default: false,
      },
    },
    computed: {
      isLoading() {
        return this.status === 'loading';
      },
      statusObj() {
        return {
          group: this.status,
          icon: `status_${this.status}`,
        };
      },
    },
  };
</script>
<template>
  <div class="space-children d-flex append-right-10 widget-status-icon">
    <div
      v-if="isLoading"
      class="mr-widget-icon"
    >
      <gl-loading-icon />
    </div>

    <ci-icon
      v-else
      :status="statusObj"
      :size="24"
    />

    <button
      v-if="showDisabledButton"
      type="button"
      class="js-disabled-merge-button btn btn-success btn-sm"
      disabled="true"
    >
      {{ s__("mrWidget|Merge") }}
    </button>
  </div>
</template>

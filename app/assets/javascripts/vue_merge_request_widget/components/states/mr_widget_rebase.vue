<script>
  import statusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon';
  import loadingIcon from '~/vue_shared/components/loading_icon.vue';

  export default {
    props: {
      mr: {
        type: Object,
        required: true,
      },
      service: {
        type: Object,
        required: true,
      },
    },
    components: {
      statusIcon,
      loadingIcon,
    },
    computed: {
      showDisabledButton() {
        return true;
      },
    },
  };
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon
      :status="status"
      :show-disabled-button="showDisabledButton"
      />

    <div class="rebase-state-find-class-convention media media-body space-children">
      <template>
        <span class="bold">
          Fast-forward merge is not possible.
          Rebase the source branch onto
          <span class="label-branch">{{mr.targetBranch}}</span>
          to allow this merge request to be merged.
        </span>
      </template>
    </div>
  </div>
</template>

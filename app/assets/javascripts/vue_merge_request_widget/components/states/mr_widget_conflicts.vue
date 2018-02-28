<script>
  import statusIcon from '../mr_widget_status_icon.vue';

  export default {
    name: 'MRWidgetConflicts',
    components: {
      statusIcon,
    },
    props: {
      /* TODO: This is providing all store and service down when it
      only needs a few props */
      mr: {
        type: Object,
        required: true,
        default: () => ({}),
      },
    },
  };
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon
      status="warning"
      :show-disabled-button="true"
    />

    <div class="media-body space-children">
      <span
        v-if="mr.shouldBeRebased"
        class="bold"
      >
        {{ s__(`mrWidget|Fast-forward merge is not possible.
To merge this request, first rebase locally.`) }}
      </span>
      <template v-else>
        <span class="bold">
          {{ s__("mrWidget|There are merge conflicts") }}<span v-if="!mr.canMerge">.</span>
          <span v-if="!mr.canMerge">
            {{ s__(`mrWidget|Resolve these conflicts or ask someone
            with write access to this repository to merge it locally`) }}
          </span>
        </span>
        <a
          v-if="mr.canMerge && mr.conflictResolutionPath"
          :href="mr.conflictResolutionPath"
          class="js-resolve-conflicts-button btn btn-default btn-xs"
        >
          {{ s__("mrWidget|Resolve conflicts") }}
        </a>
        <button
          v-if="mr.canMerge"
          class="js-merge-locally-button btn btn-default btn-xs"
          data-toggle="modal"
          data-target="#modal_merge_info"
        >
          {{ s__("mrWidget|Merge locally") }}
        </button>
      </template>
    </div>
  </div>
</template>

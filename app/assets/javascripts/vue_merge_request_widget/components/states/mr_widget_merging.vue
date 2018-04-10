<script>
  import statusIcon from '../mr_widget_status_icon.vue';

  export default {
    name: 'MRWidgetMerging',
    components: {
      statusIcon,
    },
    props: {
      mr: {
        type: Object,
        required: true,
        default: () => ({}),
      },
    },
  };
</script>
<template>
  <div class="mr-widget-body mr-state-locked media">
    <status-icon status="loading" />
    <div class="media-body">
      <h4>
        {{ s__("mrWidget|This merge request is in the process of being merged") }}
      </h4>
      <section class="mr-info-list">
        <p>
          {{ s__("mrWidget|The changes will be merged into") }}
          <span class="label-branch">
            <a :href="mr.targetBranchPath">{{ mr.targetBranch }}</a>
          </span>
        </p>
      </section>
    </div>
  </div>
</template>

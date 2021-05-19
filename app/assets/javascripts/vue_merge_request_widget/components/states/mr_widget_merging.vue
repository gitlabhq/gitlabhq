<script>
import { MERGE_ACTIVE_STATUS_PHRASES } from '../../constants';
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
  data() {
    const statusCount = MERGE_ACTIVE_STATUS_PHRASES.length;

    return {
      mergeStatus: MERGE_ACTIVE_STATUS_PHRASES[Math.floor(Math.random() * statusCount)],
    };
  },
};
</script>
<template>
  <div class="mr-widget-body mr-state-locked media">
    <status-icon status="loading" />
    <div class="media-body">
      <h4>
        {{ mergeStatus.message }}
        <gl-emoji :data-name="mergeStatus.emoji" />
      </h4>
      <section class="mr-info-list">
        <p>
          {{ s__('mrWidget|The changes will be merged into') }}
          <span class="label-branch">
            <a :href="mr.targetBranchPath">{{ mr.targetBranch }}</a>
          </span>
        </p>
      </section>
    </div>
  </div>
</template>

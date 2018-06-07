<script>
import { mapActions, mapState } from 'vuex';
import tooltip from '../../../vue_shared/directives/tooltip';
import Icon from '../../../vue_shared/components/icon.vue';
import { rightSidebarViews } from '../../constants';
import PipelinesList from '../pipelines/list.vue';
import JobsDetail from '../jobs/detail.vue';

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
    PipelinesList,
    JobsDetail,
  },
  computed: {
    ...mapState(['rightPane']),
    pipelinesActive() {
      return (
        this.rightPane === rightSidebarViews.pipelines ||
        this.rightPane === rightSidebarViews.jobsDetail
      );
    },
  },
  methods: {
    ...mapActions(['setRightPane']),
    clickTab(e, view) {
      e.target.blur();

      this.setRightPane(view);
    },
  },
  rightSidebarViews,
};
</script>

<template>
  <div
    class="multi-file-commit-panel ide-right-sidebar"
  >
    <div
      class="multi-file-commit-panel-inner"
      v-if="rightPane"
    >
      <component :is="rightPane" />
    </div>
    <nav class="ide-activity-bar">
      <ul class="list-unstyled">
        <li>
          <button
            v-tooltip
            data-container="body"
            data-placement="left"
            :title="__('Pipelines')"
            class="ide-sidebar-link is-right"
            :class="{
              active: pipelinesActive
            }"
            type="button"
            @click="clickTab($event, $options.rightSidebarViews.pipelines)"
          >
            <icon
              :size="16"
              name="pipeline"
            />
          </button>
        </li>
      </ul>
    </nav>
  </div>
</template>

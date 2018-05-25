<script>
import { mapActions } from 'vuex';
import tooltip from '../../../vue_shared/directives/tooltip';
import Icon from '../../../vue_shared/components/icon.vue';
import CiIcon from '../../../vue_shared/components/ci_icon.vue';
import LoadingIcon from '../../../vue_shared/components/loading_icon.vue';
import Item from './item.vue';

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
    CiIcon,
    LoadingIcon,
    Item,
  },
  props: {
    stage: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      showTooltip: false,
    };
  },
  computed: {
    collapseIcon() {
      return this.stage.isCollapsed ? 'angle-left' : 'angle-down';
    },
    showLoadingIcon() {
      return this.stage.isLoading && !this.stage.jobs.length;
    },
    jobsCount() {
      return this.stage.jobs.length;
    },
  },
  created() {
    this.fetchJobs(this.stage);
  },
  mounted() {
    const { stageTitle } = this.$refs;

    this.showTooltip = stageTitle.scrollWidth > stageTitle.offsetWidth;
  },
  methods: {
    ...mapActions('pipelines', ['fetchJobs']),
  },
};
</script>

<template>
  <div
    class="panel panel-default prepend-top-default"
  >
    <div
      class="panel-heading"
      @click="() => stage.isCollapsed = !stage.isCollapsed"
    >
      <ci-icon
        :status="stage.status"
        :size="24"
      />
      <strong
        v-tooltip="showTooltip"
        :title="showTooltip ? stage.name : null"
        data-container="body"
        class="prepend-left-8 ide-stage-title"
        ref="stageTitle"
      >
        {{ stage.name }}
      </strong>
      <div
        v-if="!stage.isLoading || stage.jobs.length"
        class="append-right-8"
      >
        <span class="badge">
          {{ jobsCount }}
        </span>
      </div>
      <icon
        :name="collapseIcon"
        css-classes="pull-right"
      />
    </div>
    <div
      class="panel-body"
      v-show="!stage.isCollapsed"
    >
      <loading-icon
        v-if="showLoadingIcon"
      />
      <template v-else>
        <item
          v-for="job in stage.jobs"
          :key="job.id"
          :job="job"
        />
      </template>
    </div>
  </div>
</template>

<style scoped>
.panel-heading {
  display: flex;
  cursor: pointer;
}
.panel-heading .ci-status-icon {
  display: flex;
  align-items: center;
}

.panel-heading .pull-right {
  margin: auto 0 auto auto;
}

.panel-body {
  padding: 0;
}

.ide-stage-title {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
</style>

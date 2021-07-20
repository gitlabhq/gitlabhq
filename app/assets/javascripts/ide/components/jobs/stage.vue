<script>
import { GlLoadingIcon, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import CiIcon from '../../../vue_shared/components/ci_icon.vue';
import Item from './item.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    CiIcon,
    Item,
    GlLoadingIcon,
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
  mounted() {
    const { stageTitle } = this.$refs;

    this.showTooltip = stageTitle.scrollWidth > stageTitle.offsetWidth;

    this.$emit('fetch', this.stage);
  },
  methods: {
    toggleCollapsed() {
      this.$emit('toggleCollapsed', this.stage.id);
    },
    clickViewLog(job) {
      this.$emit('clickViewLog', job);
    },
  },
};
</script>

<template>
  <div class="ide-stage card gl-mt-3">
    <div
      ref="cardHeader"
      :class="{
        'border-bottom-0': stage.isCollapsed,
      }"
      class="card-header"
      @click="toggleCollapsed"
    >
      <ci-icon :status="stage.status" :size="24" />
      <strong
        ref="stageTitle"
        v-gl-tooltip="showTooltip"
        :title="showTooltip ? stage.name : null"
        data-container="body"
        class="gl-ml-3 text-truncate"
      >
        {{ stage.name }}
      </strong>
      <div v-if="!stage.isLoading || stage.jobs.length" class="gl-mr-3 gl-ml-2">
        <span class="badge badge-pill"> {{ jobsCount }} </span>
      </div>
      <gl-icon :name="collapseIcon" class="ide-stage-collapse-icon" />
    </div>
    <div v-show="!stage.isCollapsed" ref="jobList" class="card-body p-0">
      <gl-loading-icon v-if="showLoadingIcon" size="sm" />
      <template v-else>
        <item v-for="job in stage.jobs" :key="job.id" :job="job" @clickViewLog="clickViewLog" />
      </template>
    </div>
  </div>
</template>

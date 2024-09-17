<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlLoadingIcon, GlIcon, GlTooltipDirective, GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';
import Item from './item.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    GlBadge,
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
      return this.stage.isCollapsed ? 'chevron-lg-down' : 'chevron-lg-up';
    },
    showLoadingIcon() {
      return this.stage.isLoading && !this.stage.jobs.length;
    },
    stageTitle() {
      const prefix = __('Stage');
      return `${prefix}: ${this.stage.name}`;
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
      :class="{
        'border-bottom-0': stage.isCollapsed,
      }"
      class="card-header gl-flex gl-cursor-pointer gl-items-center"
      data-testid="card-header"
      @click="toggleCollapsed"
    >
      <strong
        ref="stageTitle"
        v-gl-tooltip="showTooltip"
        :title="showTooltip ? stage.name : null"
        data-container="body"
        class="gl-truncate"
        data-testid="stage-title"
      >
        {{ stageTitle }}
      </strong>
      <div v-if="!stage.isLoading || stage.jobs.length" class="gl-ml-2 gl-mr-3">
        <gl-badge>{{ jobsCount }}</gl-badge>
      </div>
      <gl-icon :name="collapseIcon" class="gl-absolute gl-right-5" />
    </div>
    <div v-show="!stage.isCollapsed" class="card-body p-0" data-testid="job-list">
      <gl-loading-icon v-if="showLoadingIcon" size="sm" />
      <template v-else>
        <item v-for="job in stage.jobs" :key="job.id" :job="job" @clickViewLog="clickViewLog" />
      </template>
    </div>
  </div>
</template>

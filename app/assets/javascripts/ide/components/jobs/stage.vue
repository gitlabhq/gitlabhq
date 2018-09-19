<script>
import tooltip from '../../../vue_shared/directives/tooltip';
import Icon from '../../../vue_shared/components/icon.vue';
import CiIcon from '../../../vue_shared/components/ci_icon.vue';
import Item from './item.vue';

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
    CiIcon,
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
  <div
    class="ide-stage card prepend-top-default"
  >
    <div
      :class="{
        'border-bottom-0': stage.isCollapsed
      }"
      class="card-header"
      @click="toggleCollapsed"
    >
      <ci-icon
        :status="stage.status"
        :size="24"
      />
      <strong
        v-tooltip="showTooltip"
        ref="stageTitle"
        :title="showTooltip ? stage.name : null"
        data-container="body"
        class="prepend-left-8 ide-stage-title"
      >
        {{ stage.name }}
      </strong>
      <div
        v-if="!stage.isLoading || stage.jobs.length"
        class="append-right-8 prepend-left-4"
      >
        <span class="badge badge-pill">
          {{ jobsCount }}
        </span>
      </div>
      <icon
        :name="collapseIcon"
        css-classes="ide-stage-collapse-icon"
      />
    </div>
    <div
      v-show="!stage.isCollapsed"
      class="card-body"
    >
      <gl-loading-icon
        v-if="showLoadingIcon"
      />
      <template v-else>
        <item
          v-for="job in stage.jobs"
          :key="job.id"
          :job="job"
          @clickViewLog="clickViewLog"
        />
      </template>
    </div>
  </div>
</template>

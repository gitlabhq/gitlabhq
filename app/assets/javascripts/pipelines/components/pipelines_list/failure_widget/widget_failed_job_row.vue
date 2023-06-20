<script>
import { GlCollapse, GlIcon, GlLink } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  components: {
    CiIcon,
    GlCollapse,
    GlIcon,
    GlLink,
  },
  directives: {
    SafeHtml,
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isJobLogVisible: false,
      isHovered: false,
    };
  },
  computed: {
    activeClass() {
      return this.isHovered ? 'gl-bg-gray-50' : '';
    },
    isVisibleId() {
      return `log-${this.isJobLogVisible ? 'is-visible' : 'is-hidden'}`;
    },
    jobChevronName() {
      return this.isJobLogVisible ? 'chevron-down' : 'chevron-right';
    },
    jobTrace() {
      return this.job?.trace?.htmlSummary || this.$options.i18n.noTraceText;
    },
    parsedJobId() {
      return getIdFromGraphQLId(this.job.id);
    },
    tooltipText() {
      return sprintf(this.$options.i18n.jobActionTooltipText, { jobName: this.job.name });
    },
  },
  methods: {
    setActiveRow() {
      this.isHovered = true;
    },
    resetActiveRow() {
      this.isHovered = false;
    },
    toggleJobLog(e) {
      // Do not toggle the log visibility when clicking on a link
      if (e.target.tagName === 'A') {
        return;
      }

      this.isJobLogVisible = !this.isJobLogVisible;
    },
  },
  i18n: {
    jobActionTooltipText: s__('Pipelines|Retry %{jobName} Job'),
    noTraceText: s__('Job|No job log'),
  },
};
</script>
<template>
  <div class="container-fluid gl-grid-tpl-rows-auto">
    <div
      class="row gl-py-4 gl-cursor-pointer gl-display-flex gl-align-items-center"
      :class="activeClass"
      :aria-pressed="isJobLogVisible"
      role="button"
      tabindex="0"
      data-testid="widget-row"
      @click="toggleJobLog"
      @keyup.enter="toggleJobLog"
      @keyup.space="toggleJobLog"
      @mouseover="setActiveRow"
      @mouseout="resetActiveRow"
    >
      <div class="col-6 gl-text-gray-900 gl-font-weight-bold gl-text-left">
        <gl-icon :name="jobChevronName" class="gl-fill-blue-500" />
        <ci-icon :status="job.detailedStatus" />
        {{ job.name }}
      </div>
      <div class="col-2 gl-text-left">{{ job.stage.name }}</div>
      <div class="col-2 gl-text-left">
        <gl-link :href="job.webPath">#{{ parsedJobId }}</gl-link>
      </div>
    </div>
    <div class="row">
      <gl-collapse :visible="isJobLogVisible" class="gl-w-full">
        <pre
          v-safe-html="jobTrace"
          class="gl-bg-gray-900 gl-text-white"
          :data-testid="isVisibleId"
        ></pre>
      </gl-collapse>
    </div>
  </div>
</template>

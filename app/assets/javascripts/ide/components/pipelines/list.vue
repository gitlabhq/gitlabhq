<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlLoadingIcon, GlIcon, GlTabs, GlTab, GlBadge, GlAlert } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import JobsList from '../jobs/list.vue';
import EmptyState from './empty_state.vue';

const CLASSES_FLEX_VERTICAL_CENTER = ['gl-h-full', 'gl-flex', 'gl-flex-col', 'gl-justify-center'];

export default {
  components: {
    GlIcon,
    CiIcon,
    JobsList,
    EmptyState,
    GlLoadingIcon,
    GlTabs,
    GlTab,
    GlBadge,
    GlAlert,
  },
  directives: {
    SafeHtml,
  },
  computed: {
    ...mapGetters(['currentProject']),
    ...mapGetters('pipelines', ['jobsCount', 'failedJobsCount', 'failedStages', 'pipelineFailed']),
    ...mapState('pipelines', [
      'isLoadingPipeline',
      'hasLoadedPipeline',
      'latestPipeline',
      'stages',
      'isLoadingJobs',
    ]),
    showLoadingIcon() {
      return this.isLoadingPipeline && !this.hasLoadedPipeline;
    },
  },
  created() {
    this.fetchLatestPipeline();
  },
  methods: {
    ...mapActions('pipelines', ['fetchLatestPipeline']),
  },
  CLASSES_FLEX_VERTICAL_CENTER,
};
</script>

<template>
  <div class="ide-pipeline">
    <div v-if="showLoadingIcon" :class="$options.CLASSES_FLEX_VERTICAL_CENTER">
      <gl-loading-icon size="lg" />
    </div>
    <template v-else-if="hasLoadedPipeline">
      <header v-if="latestPipeline" class="ide-tree-header ide-pipeline-header">
        <ci-icon :status="latestPipeline.details.status" />
        <span class="gl-ml-3">
          <strong> {{ __('Pipeline') }} </strong>
          <a
            :href="latestPipeline.path"
            target="_blank"
            class="ide-external-link position-relative"
          >
            #{{ latestPipeline.id }} <gl-icon :size="12" name="external-link" />
          </a>
        </span>
      </header>
      <div v-if="!latestPipeline" :class="$options.CLASSES_FLEX_VERTICAL_CENTER">
        <empty-state />
      </div>
      <gl-alert
        v-else-if="latestPipeline.yamlError"
        variant="danger"
        :dismissible="false"
        class="gl-mt-5"
      >
        <p class="gl-mb-0">{{ __('Unable to create pipeline') }}</p>
        <p class="break-word gl-mb-0">{{ latestPipeline.yamlError }}</p>
      </gl-alert>
      <gl-tabs v-else>
        <gl-tab :active="!pipelineFailed">
          <template #title>
            {{ __('Jobs') }}
            <gl-badge v-if="jobsCount" class="gl-tab-counter-badge">{{ jobsCount }}</gl-badge>
          </template>
          <jobs-list :loading="isLoadingJobs" :stages="stages" />
        </gl-tab>
        <gl-tab :active="pipelineFailed">
          <template #title>
            {{ __('Failed Jobs') }}
            <gl-badge v-if="failedJobsCount" class="gl-tab-counter-badge">{{
              failedJobsCount
            }}</gl-badge>
          </template>
          <jobs-list :loading="isLoadingJobs" :stages="failedStages" />
        </gl-tab>
      </gl-tabs>
    </template>
  </div>
</template>

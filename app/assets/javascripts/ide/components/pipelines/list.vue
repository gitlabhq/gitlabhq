<script>
import {
  GlLoadingIcon,
  GlIcon,
  GlSafeHtmlDirective as SafeHtml,
  GlTabs,
  GlTab,
  GlBadge,
  GlAlert,
} from '@gitlab/ui';
import { escape } from 'lodash';
import { mapActions, mapGetters, mapState } from 'vuex';
import IDEServices from '~/ide/services';
import { sprintf, __ } from '../../../locale';
import EmptyState from '../../../pipelines/components/pipelines_list/empty_state.vue';
import CiIcon from '../../../vue_shared/components/ci_icon.vue';
import JobsList from '../jobs/list.vue';

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
    ...mapState(['pipelinesEmptyStateSvgPath']),
    ...mapGetters(['currentProject']),
    ...mapGetters('pipelines', ['jobsCount', 'failedJobsCount', 'failedStages', 'pipelineFailed']),
    ...mapState('pipelines', [
      'isLoadingPipeline',
      'hasLoadedPipeline',
      'latestPipeline',
      'stages',
      'isLoadingJobs',
    ]),
    ciLintText() {
      return sprintf(
        __('You can test your .gitlab-ci.yml in %{linkStart}CI Lint%{linkEnd}.'),
        {
          linkStart: `<a href="${escape(this.currentProject.web_url)}/-/ci/lint">`,
          linkEnd: '</a>',
        },
        false,
      );
    },
    showLoadingIcon() {
      return this.isLoadingPipeline && !this.hasLoadedPipeline;
    },
  },
  created() {
    this.fetchLatestPipeline();
    IDEServices.pingUsage(this.currentProject.path_with_namespace);
  },
  methods: {
    ...mapActions('pipelines', ['fetchLatestPipeline']),
  },
};
</script>

<template>
  <div class="ide-pipeline">
    <gl-loading-icon v-if="showLoadingIcon" size="lg" class="gl-mt-3" />
    <template v-else-if="hasLoadedPipeline">
      <header v-if="latestPipeline" class="ide-tree-header ide-pipeline-header">
        <ci-icon :status="latestPipeline.details.status" :size="24" class="d-flex" />
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
      <empty-state
        v-if="!latestPipeline"
        :empty-state-svg-path="pipelinesEmptyStateSvgPath"
        :can-set-ci="true"
        class="mb-auto mt-auto"
      />
      <gl-alert
        v-else-if="latestPipeline.yamlError"
        variant="danger"
        :dismissible="false"
        class="gl-mt-5"
      >
        <p class="gl-mb-0">{{ __('Found errors in your .gitlab-ci.yml:') }}</p>
        <p class="gl-mb-0 break-word">{{ latestPipeline.yamlError }}</p>
        <p v-safe-html="ciLintText" class="gl-mb-0"></p>
      </gl-alert>
      <gl-tabs v-else>
        <gl-tab :active="!pipelineFailed">
          <template #title>
            {{ __('Jobs') }}
            <gl-badge v-if="jobsCount" size="sm" class="gl-tab-counter-badge">{{
              jobsCount
            }}</gl-badge>
          </template>
          <jobs-list :loading="isLoadingJobs" :stages="stages" />
        </gl-tab>
        <gl-tab :active="pipelineFailed">
          <template #title>
            {{ __('Failed Jobs') }}
            <gl-badge v-if="failedJobsCount" size="sm" class="gl-tab-counter-badge">{{
              failedJobsCount
            }}</gl-badge>
          </template>
          <jobs-list :loading="isLoadingJobs" :stages="failedStages" />
        </gl-tab>
      </gl-tabs>
    </template>
  </div>
</template>

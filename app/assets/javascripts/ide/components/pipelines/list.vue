<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { escape as esc } from 'lodash';
import { GlLoadingIcon } from '@gitlab/ui';
import { sprintf, __ } from '../../../locale';
import Icon from '../../../vue_shared/components/icon.vue';
import CiIcon from '../../../vue_shared/components/ci_icon.vue';
import Tabs from '../../../vue_shared/components/tabs/tabs';
import Tab from '../../../vue_shared/components/tabs/tab.vue';
import EmptyState from '../../../pipelines/components/empty_state.vue';
import JobsList from '../jobs/list.vue';

export default {
  components: {
    Icon,
    CiIcon,
    Tabs,
    Tab,
    JobsList,
    EmptyState,
    GlLoadingIcon,
  },
  computed: {
    ...mapState(['pipelinesEmptyStateSvgPath', 'links']),
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
          linkStart: `<a href="${esc(this.currentProject.web_url)}/-/ci/lint">`,
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
  },
  methods: {
    ...mapActions('pipelines', ['fetchLatestPipeline']),
  },
};
</script>

<template>
  <div class="ide-pipeline">
    <gl-loading-icon v-if="showLoadingIcon" size="lg" class="prepend-top-default" />
    <template v-else-if="hasLoadedPipeline">
      <header v-if="latestPipeline" class="ide-tree-header ide-pipeline-header">
        <ci-icon :status="latestPipeline.details.status" :size="24" class="d-flex" />
        <span class="prepend-left-8">
          <strong> {{ __('Pipeline') }} </strong>
          <a
            :href="latestPipeline.path"
            target="_blank"
            class="ide-external-link position-relative"
          >
            #{{ latestPipeline.id }} <icon :size="12" name="external-link" />
          </a>
        </span>
      </header>
      <empty-state
        v-if="!latestPipeline"
        :help-page-path="links.ciHelpPagePath"
        :empty-state-svg-path="pipelinesEmptyStateSvgPath"
        :can-set-ci="true"
        class="mb-auto mt-auto"
      />
      <div v-else-if="latestPipeline.yamlError" class="bs-callout bs-callout-danger">
        <p class="append-bottom-0">{{ __('Found errors in your .gitlab-ci.yml:') }}</p>
        <p class="append-bottom-0 break-word">{{ latestPipeline.yamlError }}</p>
        <p class="append-bottom-0" v-html="ciLintText"></p>
      </div>
      <tabs v-else class="ide-pipeline-list">
        <tab :active="!pipelineFailed">
          <template slot="title">
            {{ __('Jobs') }}
            <span v-if="jobsCount" class="badge badge-pill"> {{ jobsCount }} </span>
          </template>
          <jobs-list :loading="isLoadingJobs" :stages="stages" />
        </tab>
        <tab :active="pipelineFailed">
          <template slot="title">
            {{ __('Failed Jobs') }}
            <span v-if="failedJobsCount" class="badge badge-pill"> {{ failedJobsCount }} </span>
          </template>
          <jobs-list :loading="isLoadingJobs" :stages="failedStages" />
        </tab>
      </tabs>
    </template>
  </div>
</template>

<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { first } from 'lodash';
import { truncateSha } from '~/lib/utils/text_utility';
import { s__, n__ } from '~/locale';
import { HISTORY_PIPELINES_LIMIT } from '~/packages/details/constants';
import HistoryItem from '~/vue_shared/components/registry/history_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'PackageHistory',
  i18n: {
    createdOn: s__('PackageRegistry|%{name} version %{version} was first created %{datetime}'),
    createdByCommitText: s__('PackageRegistry|Created by commit %{link} on branch %{branch}'),
    createdByPipelineText: s__(
      'PackageRegistry|Built by pipeline %{link} triggered %{datetime} by %{author}',
    ),
    publishText: s__('PackageRegistry|Published to the %{project} Package Registry %{datetime}'),
    combinedUpdateText: s__(
      'PackageRegistry|Package updated by commit %{link} on branch %{branch}, built by pipeline %{pipeline}, and published to the registry %{datetime}',
    ),
    archivedPipelineMessageSingular: s__('PackageRegistry|Package has %{number} archived update'),
    archivedPipelineMessagePlural: s__('PackageRegistry|Package has %{number} archived updates'),
  },
  components: {
    GlLink,
    GlSprintf,
    HistoryItem,
    TimeAgoTooltip,
  },
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
    projectName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      showDescription: false,
    };
  },
  computed: {
    pipelines() {
      return this.packageEntity.pipelines || [];
    },
    firstPipeline() {
      return first(this.pipelines);
    },
    lastPipelines() {
      return this.pipelines.slice(1).slice(-HISTORY_PIPELINES_LIMIT);
    },
    showPipelinesInfo() {
      return Boolean(this.firstPipeline?.id);
    },
    archiviedLines() {
      return Math.max(this.pipelines.length - HISTORY_PIPELINES_LIMIT - 1, 0);
    },
    archivedPipelineMessage() {
      return n__(
        this.$options.i18n.archivedPipelineMessageSingular,
        this.$options.i18n.archivedPipelineMessagePlural,
        this.archiviedLines,
      );
    },
  },
  methods: {
    truncate(value) {
      return truncateSha(value);
    },
  },
};
</script>

<template>
  <div class="issuable-discussion">
    <h3 class="gl-font-lg" data-testid="title">{{ __('History') }}</h3>
    <ul class="timeline main-notes-list notes gl-mb-4" data-testid="timeline">
      <history-item icon="clock" data-testid="created-on">
        <gl-sprintf :message="$options.i18n.createdOn">
          <template #name>
            <strong>{{ packageEntity.name }}</strong>
          </template>
          <template #version>
            <strong>{{ packageEntity.version }}</strong>
          </template>
          <template #datetime>
            <time-ago-tooltip :time="packageEntity.created_at" />
          </template>
        </gl-sprintf>
      </history-item>

      <template v-if="showPipelinesInfo">
        <!-- FIRST PIPELINE BLOCK -->
        <history-item icon="commit" data-testid="first-pipeline-commit">
          <gl-sprintf :message="$options.i18n.createdByCommitText">
            <template #link>
              <gl-link :href="firstPipeline.project.commit_url"
                >#{{ truncate(firstPipeline.sha) }}</gl-link
              >
            </template>
            <template #branch>
              <strong>{{ firstPipeline.ref }}</strong>
            </template>
          </gl-sprintf>
        </history-item>
        <history-item icon="pipeline" data-testid="first-pipeline-pipeline">
          <gl-sprintf :message="$options.i18n.createdByPipelineText">
            <template #link>
              <gl-link :href="firstPipeline.project.pipeline_url">#{{ firstPipeline.id }}</gl-link>
            </template>
            <template #datetime>
              <time-ago-tooltip :time="firstPipeline.created_at" />
            </template>
            <template #author>{{ firstPipeline.user.name }}</template>
          </gl-sprintf>
        </history-item>
      </template>

      <!-- PUBLISHED LINE -->
      <history-item icon="package" data-testid="published">
        <gl-sprintf :message="$options.i18n.publishText">
          <template #project>
            <strong>{{ projectName }}</strong>
          </template>
          <template #datetime>
            <time-ago-tooltip :time="packageEntity.created_at" />
          </template>
        </gl-sprintf>
      </history-item>

      <history-item v-if="archiviedLines" icon="history" data-testid="archived">
        <gl-sprintf :message="archivedPipelineMessage">
          <template #number>
            <strong>{{ archiviedLines }}</strong>
          </template>
        </gl-sprintf>
      </history-item>

      <!-- PIPELINES LIST ENTRIES -->
      <history-item
        v-for="pipeline in lastPipelines"
        :key="pipeline.id"
        icon="pencil"
        data-testid="pipeline-entry"
      >
        <gl-sprintf :message="$options.i18n.combinedUpdateText">
          <template #link>
            <gl-link :href="pipeline.project.commit_url">#{{ truncate(pipeline.sha) }}</gl-link>
          </template>
          <template #branch>
            <strong>{{ pipeline.ref }}</strong>
          </template>
          <template #pipeline>
            <gl-link :href="pipeline.project.pipeline_url">#{{ pipeline.id }}</gl-link>
          </template>
          <template #datetime>
            <time-ago-tooltip :time="pipeline.created_at" />
          </template>
        </gl-sprintf>
      </history-item>
    </ul>
  </div>
</template>

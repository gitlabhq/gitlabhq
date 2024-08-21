<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { first } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { truncateSha } from '~/lib/utils/text_utility';
import { s__, n__ } from '~/locale';
import Tracking from '~/tracking';
import { packageTypeToTrackCategory } from '~/packages_and_registries/package_registry/utils';
import { HISTORY_PIPELINES_LIMIT } from '~/packages_and_registries/shared/constants';
import HistoryItem from '~/vue_shared/components/registry/history_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import {
  GRAPHQL_PACKAGE_PIPELINES_PAGE_SIZE,
  FETCH_PACKAGE_PIPELINES_ERROR_MESSAGE,
  TRACKING_ACTION_CLICK_PIPELINE_LINK,
  TRACKING_ACTION_CLICK_COMMIT_LINK,
  TRACKING_LABEL_PACKAGE_HISTORY,
} from '../../constants';
import getPackagePipelinesQuery from '../../graphql/queries/get_package_pipelines.query.graphql';
import PackageHistoryLoader from './package_history_loader.vue';

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
    fetchPackagePipelinesErrorMessage: FETCH_PACKAGE_PIPELINES_ERROR_MESSAGE,
  },
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
    HistoryItem,
    PackageHistoryLoader,
    TimeAgoTooltip,
  },
  mixins: [Tracking.mixin()],
  TRACKING_ACTION_CLICK_PIPELINE_LINK,
  TRACKING_ACTION_CLICK_COMMIT_LINK,
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
  apollo: {
    pipelines: {
      query: getPackagePipelinesQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.package?.pipelines?.nodes || [];
      },
      error(error) {
        this.fetchPackagePipelinesError = true;
        Sentry.captureException(error);
      },
    },
  },
  data() {
    return {
      pipelines: [],
      fetchPackagePipelinesError: false,
    };
  },
  computed: {
    firstPipeline() {
      return first(this.pipelines);
    },
    lastPipelines() {
      return this.pipelines.slice(1).slice(-HISTORY_PIPELINES_LIMIT);
    },
    showPipelinesInfo() {
      return Boolean(this.firstPipeline?.id);
    },
    archivedLines() {
      return Math.max(this.pipelines.length - HISTORY_PIPELINES_LIMIT - 1, 0);
    },
    archivedPipelineMessage() {
      return n__(
        'PackageRegistry|Package has %{updatesCount} archived update',
        'PackageRegistry|Package has %{updatesCount} archived updates',
        this.archivedLines,
      );
    },
    isLoading() {
      return this.$apollo.queries.pipelines.loading;
    },
    queryVariables() {
      return {
        id: this.packageEntity.id,
        first: GRAPHQL_PACKAGE_PIPELINES_PAGE_SIZE,
      };
    },
    tracking() {
      return {
        category: packageTypeToTrackCategory(this.packageType),
      };
    },
  },
  methods: {
    truncate(value) {
      return truncateSha(value);
    },
    convertToBaseId(value) {
      return getIdFromGraphQLId(value);
    },
    trackPipelineClick() {
      this.track(TRACKING_ACTION_CLICK_PIPELINE_LINK, { label: TRACKING_LABEL_PACKAGE_HISTORY });
    },
    trackCommitClick() {
      this.track(TRACKING_ACTION_CLICK_COMMIT_LINK, { label: TRACKING_LABEL_PACKAGE_HISTORY });
    },
  },
};
</script>

<template>
  <div class="issuable-discussion">
    <h3 class="gl-text-lg" data-testid="title">{{ __('History') }}</h3>
    <gl-alert
      v-if="fetchPackagePipelinesError"
      variant="danger"
      @dismiss="fetchPackagePipelinesError = false"
    >
      {{ $options.i18n.fetchPackagePipelinesErrorMessage }}
    </gl-alert>
    <package-history-loader v-if="isLoading" />
    <ul v-else class="timeline main-notes-list notes gl-mb-4" data-testid="timeline">
      <history-item icon="clock" data-testid="created-on">
        <gl-sprintf :message="$options.i18n.createdOn">
          <template #name>
            <strong>{{ packageEntity.name }}</strong>
          </template>
          <template #version>
            <strong>{{ packageEntity.version }}</strong>
          </template>
          <template #datetime>
            <time-ago-tooltip :time="packageEntity.createdAt" />
          </template>
        </gl-sprintf>
      </history-item>

      <template v-if="showPipelinesInfo">
        <!-- FIRST PIPELINE BLOCK -->
        <history-item icon="commit" data-testid="first-pipeline-commit">
          <gl-sprintf :message="$options.i18n.createdByCommitText">
            <template #link>
              <gl-link :href="firstPipeline.commitPath" @click="trackCommitClick">{{
                truncate(firstPipeline.sha)
              }}</gl-link>
            </template>
            <template #branch>
              <strong>{{ firstPipeline.ref }}</strong>
            </template>
          </gl-sprintf>
        </history-item>
        <history-item icon="pipeline" data-testid="first-pipeline-pipeline">
          <gl-sprintf :message="$options.i18n.createdByPipelineText">
            <template #link>
              <gl-link :href="firstPipeline.path" @click="trackPipelineClick"
                >#{{ convertToBaseId(firstPipeline.id) }}</gl-link
              >
            </template>
            <template #datetime>
              <time-ago-tooltip :time="firstPipeline.createdAt" />
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
            <time-ago-tooltip :time="packageEntity.createdAt" />
          </template>
        </gl-sprintf>
      </history-item>

      <history-item v-if="archivedLines" icon="history" data-testid="archived">
        <gl-sprintf :message="archivedPipelineMessage">
          <template #updatesCount>
            <strong>{{ archivedLines }}</strong>
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
            <gl-link :href="pipeline.commitPath" @click="trackCommitClick">{{
              truncate(pipeline.sha)
            }}</gl-link>
          </template>
          <template #branch>
            <strong>{{ pipeline.ref }}</strong>
          </template>
          <template #pipeline>
            <gl-link :href="pipeline.path" @click="trackPipelineClick"
              >#{{ convertToBaseId(pipeline.id) }}</gl-link
            >
          </template>
          <template #datetime>
            <time-ago-tooltip :time="pipeline.createdAt" />
          </template>
        </gl-sprintf>
      </history-item>
    </ul>
  </div>
</template>

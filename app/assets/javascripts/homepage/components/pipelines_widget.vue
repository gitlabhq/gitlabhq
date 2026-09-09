<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { InternalEvents } from '~/tracking';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_PIPELINES,
} from '../tracking_constants';
import BaseWidget from './base_widget.vue';

const PIPELINES_API_PATH = '/api/:version/pipelines';
const MAX_PIPELINES = 6;
// The API drops pipelines the user cannot see only after paginating, so a
// page can come back short. Overfetch and trim client-side.
const FETCH_PER_PAGE = 20;
// Only merge request pipelines: keeps the list focused on in-flight work and
// naturally excludes multi-project downstream pipelines.
const MERGE_REQUEST_SOURCE = 'merge_request_event';

export default {
  name: 'PipelinesWidget',
  components: {
    BaseWidget,
    CiIcon,
    GlSkeletonLoader,
    TimeAgoTooltip,
    TooltipOnTruncate,
  },
  mixins: [InternalEvents.mixin()],
  data() {
    return {
      pipelines: [],
      isLoading: false,
      hasError: false,
    };
  },
  created() {
    this.fetchPipelines();
  },
  methods: {
    async fetchPipelines() {
      this.isLoading = true;
      this.hasError = false;
      try {
        const { data } = await axios.get(buildApiUrl(PIPELINES_API_PATH), {
          params: { per_page: FETCH_PER_PAGE, source: MERGE_REQUEST_SOURCE },
        });
        this.pipelines = data.slice(0, MAX_PIPELINES).map((pipeline) => ({
          ...pipeline,
          title: pipeline.merge_request?.title || pipeline.name || pipeline.ref,
          projectFullName: pipeline.project.name_with_namespace,
        }));
      } catch (error) {
        Sentry.captureException(error);
        this.hasError = true;
      } finally {
        this.isLoading = false;
      }
    },
    handlePipelineClick() {
      this.trackEvent(EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE, {
        label: TRACKING_LABEL_PIPELINES,
      });
    },
  },
  MAX_PIPELINES,
};
</script>

<template>
  <base-widget data-testid="homepage-pipelines-widget" @visible="fetchPipelines">
    <h2 class="gl-heading-4 gl-mb-4">{{ __('Pipelines') }}</h2>

    <p v-if="hasError" class="gl-mb-0" data-testid="pipelines-widget-error">
      {{
        s__(
          'HomePagePipelinesWidget|Your pipelines are not available. Please refresh the page to try again.',
        )
      }}
    </p>

    <div v-else-if="isLoading" class="gl-flex gl-flex-col gl-gap-y-4 gl-pt-3">
      <gl-skeleton-loader
        v-for="i in $options.MAX_PIPELINES"
        :key="i"
        :lines="1"
        :equal-width-lines="true"
      />
    </div>

    <p v-else-if="!pipelines.length" class="gl-mb-0" data-testid="pipelines-widget-empty-state">
      {{ s__('HomePagePipelinesWidget|Pipelines for your merge requests will appear here.') }}
    </p>

    <ul v-else class="gl-m-0 gl-list-none gl-p-0">
      <li v-for="pipeline in pipelines" :key="pipeline.id">
        <!-- eslint-disable local-rules/vue-no-web-url -- the REST pipelines API only exposes the absolute web_url -->
        <a
          :href="pipeline.web_url"
          class="-gl-mx-3 gl-flex gl-items-center gl-gap-3 gl-rounded-base gl-p-3 gl-text-default hover:gl-bg-subtle hover:gl-text-default hover:gl-no-underline"
          @click="handlePipelineClick"
        >
          <!-- eslint-enable local-rules/vue-no-web-url -->
          <ci-icon :status="pipeline.detailed_status" :use-link="false" class="gl-shrink-0" />
          <span class="gl-flex gl-min-w-0 gl-grow gl-flex-col">
            <tooltip-on-truncate
              :title="pipeline.title"
              class="gl-overflow-hidden gl-text-ellipsis gl-whitespace-nowrap"
            >
              {{ pipeline.title }}
            </tooltip-on-truncate>
            <span class="gl-text-sm gl-text-subtle">{{ pipeline.projectFullName }}</span>
          </span>
          <time-ago-tooltip
            :time="pipeline.created_at"
            class="gl-shrink-0 gl-text-sm gl-text-subtle"
          />
        </a>
      </li>
    </ul>
  </base-widget>
</template>

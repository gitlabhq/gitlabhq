<script>
import {
  GlResizeObserverDirective,
  GlTooltipDirective,
  GlButton,
  GlLoadingIcon,
  GlAlert,
  GlLink,
  GlSprintf,
  GlAvatarLink,
  GlAvatarLabeled,
  GlTooltip,
} from '@gitlab/ui';
import { throttle, isEmpty } from 'lodash-es';
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState, mapActions } from 'vuex';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';
import { DOCS_URL } from '~/constants';
import { TYPENAME_CI_BUILD } from '~/graphql_shared/constants';
import { isGid, getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import { glEmojiTag } from '~/emoji';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import DetailLayout from '~/vue_shared/components/detail_layout.vue';
import PanelActionsPortal from '~/vue_shared/components/panel_actions_portal.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import JobLogTopBar from '~/ci/job_details/components/job_log_top_bar.vue';
import RootCauseAnalysisButton from 'ee_else_ce/ci/job_details/components/root_cause_analysis_button.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import glAbilitiesMixin from '~/vue_shared/mixins/gl_abilities_mixin';
import { __, s__, sprintf } from '~/locale';
import delayedJobMixin from '~/ci/mixins/delayed_job_mixin';
import Log from '~/ci/job_details/components/log/log.vue';
import { MANUAL_STATUS } from '~/ci/constants';
import getJobQuery from './graphql/queries/get_job.query.graphql';
import jobCiStatusUpdatedSubscription from './graphql/subscriptions/job_ci_status_updated.subscription.graphql';
import JobRunForm from './components/job_run_form.vue';
import EmptyState from './components/empty_state.vue';
import EnvironmentsBlock from './components/environments_block.vue';
import ErasedBlock from './components/erased_block.vue';
import JobSourceBadge from './components/job_source_badge.vue';
import StuckBlock from './components/stuck_block.vue';
import UnmetPrerequisitesBlock from './components/unmet_prerequisites_block.vue';
import Sidebar from './components/sidebar/sidebar.vue';
import SidebarHeader from './components/sidebar/sidebar_header.vue';

const STATIC_PANEL_WRAPPER_SELECTOR = '.js-static-panel-inner';
const TOP_BAR_STICKY_OFFSET = 8;

export default {
  name: 'JobPageApp',
  i18n: {
    archivedTitle: s__('Job|This job is archived'),
    archivedBody: s__(
      'Job|You can still view the log and download artifacts, but retry, cancel, and manual job actions are disabled. %{linkStart}Learn more about archived pipelines%{linkEnd}.',
    ),
    newIssue: __('New issue'),
    toggleSidebar: __('Toggle sidebar'),
  },
  archivedDocsPath: `${DOCS_URL}/administration/settings/continuous_integration/#archive-pipelines`,
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
  EMOJI_REF: 'EMOJI_REF',
  components: {
    DetailLayout,
    PanelActionsPortal,
    CiIcon,
    TimeagoTooltip,
    JobSourceBadge,
    EmptyState,
    JobRunForm,
    EnvironmentsBlock,
    ErasedBlock,
    Log,
    JobLogTopBar,
    RootCauseAnalysisButton,
    StuckBlock,
    UnmetPrerequisitesBlock,
    Sidebar,
    SidebarHeader,
    GlButton,
    GlLoadingIcon,
    GlAlert,
    GlLink,
    GlSprintf,
    GlAvatarLink,
    GlAvatarLabeled,
    GlTooltip,
  },
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
    GlResizeObserver: GlResizeObserverDirective,
  },
  mixins: [delayedJobMixin, glAbilitiesMixin()],
  inject: {
    projectPath: {
      default: '',
    },
  },
  apollo: {
    headerJob: {
      query: getJobQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          id: convertToGraphQLId(TYPENAME_CI_BUILD, this.job.id),
        };
      },
      skip() {
        return !this.job.id || !this.projectPath;
      },
      update({ project }) {
        return project.job;
      },
      error(error) {
        this.headerError = s__('Job|An error occurred while fetching the job status.');
        captureException(error);
      },
      subscribeToMore: {
        document: jobCiStatusUpdatedSubscription,
        variables() {
          return {
            jobId: convertToGraphQLId(TYPENAME_CI_BUILD, this.job.id),
          };
        },
        skip() {
          // ensure we have job data before updateQuery is called
          return !this.job.id || !this.headerJob;
        },
        updateQuery(
          previousData,
          {
            subscriptionData: {
              data: { ciJobStatusUpdated },
            },
          },
        ) {
          if (ciJobStatusUpdated) {
            return {
              project: {
                ...previousData.project,
                job: {
                  ...previousData.project.job,
                  detailedStatus: ciJobStatusUpdated.detailedStatus,
                },
              },
            };
          }
          return previousData;
        },
      },
    },
  },
  props: {
    artifactHelpUrl: {
      type: String,
      required: false,
      default: '',
    },
    runnerSettingsUrl: {
      type: String,
      required: false,
      default: null,
    },
    deploymentHelpUrl: {
      type: String,
      required: false,
      default: null,
    },
    logViewerPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      staticPanelWrapper: document.querySelector(STATIC_PANEL_WRAPPER_SELECTOR),
      searchResults: [],
      showUpdateVariablesState: false,
      isTopBarStuck: false,
      headerError: null,
      headerJob: null,
    };
  },
  computed: {
    ...mapState([
      'isLoading',
      'job',
      'isSidebarOpen',
      'jobLog',
      'isJobLogComplete',
      'jobLogSize',
      'isJobLogSizeVisible',
      'isScrollBottomDisabled',
      'isScrollTopDisabled',
      'hasError',
      'selectedStage',
      'fullScreenEnabled',
    ]),
    ...mapGetters([
      'hasUnmetPrerequisitesFailure',
      'shouldRenderCalloutMessage',
      'hasEnvironment',
      'hasJobLog',
      'emptyStateIllustration',
      'emptyStateAction',
      'hasOfflineRunnersForProject',
      'fullScreenAPIAndContainerAvailable',
    ]),

    shouldRenderContent() {
      return (!this.isLoading && !this.hasError) || this.hasJobLog;
    },
    headerLoading() {
      return this.$apollo.queries.headerJob.loading;
    },
    hasHeaderJob() {
      return Boolean(this.headerJob);
    },
    headerUser() {
      return this.job.user;
    },
    detailedStatus() {
      return this.headerJob?.detailedStatus || {};
    },
    shouldRenderTriggeredLabel() {
      return Boolean(this.headerJob?.startedAt);
    },
    headerTime() {
      return this.headerJob?.startedAt || this.headerJob?.createdAt;
    },
    avatarUrl() {
      // GraphQL returns `avatarUrl` and Rest `avatar_url`
      return this.headerUser?.avatarUrl || this.headerUser?.avatar_url;
    },
    userWebUrl() {
      // GraphQL returns `webUrl` and Rest `web_url`
      return this.headerUser?.webUrl || this.headerUser?.web_url;
    },
    statusTooltipHTML() {
      // Rest `status_tooltip_html` which is a ready to work
      // html for the emoji and the status text inside a tooltip.
      // GraphQL returns `status.emoji` and `status.message` which
      // needs to be combined to make the html we want.
      const { emoji } = this.headerUser?.status || {};
      const emojiHtml = emoji ? glEmojiTag(emoji) : '';

      return emojiHtml || this.headerUser?.status_tooltip_html;
    },
    statusMessage() {
      return this.headerUser?.status?.message;
    },
    userId() {
      return isGid(this.headerUser?.id)
        ? getIdFromGraphQLId(this.headerUser?.id)
        : this.headerUser?.id;
    },
    hasAlerts() {
      return Boolean(
        this.headerError ||
        this.shouldRenderHeaderCallout ||
        this.shouldRenderAttestationWarning ||
        this.job.archived,
      );
    },

    emptyStateTitle() {
      const { emptyStateIllustration, remainingTime } = this;
      const { title } = emptyStateIllustration;

      if (this.isDelayedJob) {
        return sprintf(title, { remainingTime });
      }

      return title;
    },

    shouldRenderHeaderCallout() {
      return this.shouldRenderCalloutMessage && !this.hasUnmetPrerequisitesFailure;
    },

    shouldRenderAttestationWarning() {
      return this.job.supply_chain_attestation_status === 'error';
    },

    isJobRetryable() {
      return Boolean(this.job.retry_path);
    },

    jobName() {
      return sprintf(__('%{jobName}'), { jobName: this.job.name });
    },
    jobConfirmationMessage() {
      return this.job.status?.action?.confirmation_message;
    },
    jobFailed() {
      const failedGroups = ['failed', 'failed-with-warnings'];

      return failedGroups.includes(this.job.status.group);
    },
    displayStickyFooter() {
      return this.jobFailed && this.glAbilities.troubleshootJobWithAi;
    },
    showJobForm() {
      return (
        this.showUpdateVariablesState ||
        (this.job.playable && !this.job.scheduled && !this.hasJobLog)
      );
    },
  },
  watch: {
    // Once the job log is loaded,
    // fetch the stages for the dropdown on the sidebar
    job(newVal, oldVal) {
      if (isEmpty(oldVal) && !isEmpty(newVal.pipeline)) {
        const stages = this.job.pipeline.details.stages || [];

        const defaultStage = stages.find((stage) => stage && stage.name === this.selectedStage);

        if (defaultStage) {
          this.fetchJobsForStage(defaultStage);
        }
      }

      // Only poll for job log if we are not in the manual variables form empty state.
      // This will be handled more elegantly in the future with GraphQL in https://gitlab.com/gitlab-org/gitlab/-/issues/389597
      if (newVal?.status?.group !== MANUAL_STATUS && !this.showUpdateVariablesState) {
        this.fetchJobLog();
      }
    },
  },
  created() {
    this.throttleToggleScrollButtons = throttle(this.toggleScrollButtons, 100);

    this.staticPanelWrapper?.addEventListener('scroll', this.updateScroll);

    PanelBreakpointInstance.addResizeListener(this.updateSidebar);
  },
  mounted() {
    this.updateSidebar();
  },
  beforeDestroy() {
    this.stopPollingJobLog();
    this.stopPolling();

    this.staticPanelWrapper?.removeEventListener('scroll', this.updateScroll);

    this.topBarStuckObserver?.disconnect();

    PanelBreakpointInstance.removeResizeListener(this.updateSidebar);
  },
  methods: {
    ...mapActions([
      'fetchJobLog',
      'fetchJobsForStage',
      'hideSidebar',
      'showSidebar',
      'toggleSidebar',
      'scrollBottom',
      'scrollTop',
      'stopPollingJobLog',
      'stopPolling',
      'toggleScrollButtons',
      'enterFullscreen',
      'exitFullscreen',
    ]),
    onHideManualVariablesForm() {
      this.showUpdateVariablesState = false;
    },
    onUpdateVariables() {
      this.showUpdateVariablesState = true;
    },
    updateSidebar() {
      if (PanelBreakpointInstance.isDesktop()) {
        this.showSidebar();
      } else if (this.isSidebarOpen) {
        this.hideSidebar();
      }
    },
    updateScroll() {
      this.throttleToggleScrollButtons();
    },
    observeTopBarStuck(elem) {
      this.topBarStuckObserver?.disconnect();

      if (!elem) {
        this.isTopBarStuck = false;
        return;
      }

      this.topBarStuckObserver = new IntersectionObserver(
        ([entry]) => {
          this.isTopBarStuck = !entry.isIntersecting;
        },
        {
          root: this.staticPanelWrapper,
          rootMargin: `-${TOP_BAR_STICKY_OFFSET}px 0px 0px 0px`,
          threshold: 0,
        },
      );
      this.topBarStuckObserver.observe(elem);
    },
    setSearchResults(searchResults) {
      this.searchResults = searchResults;
    },
  },
};
</script>
<template>
  <div v-gl-resize-observer="updateScroll">
    <detail-layout
      :show-sidebar="isSidebarOpen"
      :loading="!shouldRenderContent"
      data-testid="job-content"
      class="build-page"
    >
      <template v-if="headerLoading || hasHeaderJob" #heading>
        <gl-loading-icon v-if="headerLoading" size="md" inline />
        <span v-else class="gl-flex gl-items-center" data-testid="job-name">
          {{ headerJob.name }}
          <job-source-badge v-if="headerJob.source" :source="headerJob.source" />
        </span>
      </template>

      <template v-if="hasHeaderJob" #description>
        <span data-testid="job-header-content">
          <ci-icon class="gl-mr-1" :status="detailedStatus" show-status-text />
          <template v-if="shouldRenderTriggeredLabel">{{ __('Started') }}</template>
          <template v-else>{{ __('Created') }}</template>

          <timeago-tooltip :time="headerTime" />

          {{ __('by') }}

          <gl-avatar-link
            v-if="headerUser"
            :data-user-id="userId"
            :data-username="headerUser.username"
            :data-name="headerUser.name"
            :href="userWebUrl"
            target="_blank"
            class="js-user-link @sm/panel:gl-mx-2 @sm/panel:gl-align-middle"
          >
            <strong class="@sm/panel:gl-hidden">@{{ headerUser.username }}</strong>
            <gl-avatar-labeled
              :size="24"
              :src="avatarUrl"
              :label="headerUser.name"
              class="@max-sm/panel:gl-hidden"
            />

            <gl-tooltip v-if="statusMessage" :target="() => $refs[$options.EMOJI_REF]">
              {{ statusMessage }}
            </gl-tooltip>
            <span
              v-if="statusTooltipHTML"
              :ref="$options.EMOJI_REF"
              v-safe-html:[$options.safeHtmlConfig]="statusTooltipHTML"
              class="gl-ml-2"
              :data-testid="statusMessage"
            ></span>
          </gl-avatar-link>
        </span>
      </template>

      <template v-if="hasHeaderJob" #sticky-header>
        <div class="gl-flex gl-w-full gl-items-baseline gl-gap-3" data-testid="job-sticky-header">
          <ci-icon :status="detailedStatus" show-status-text />
          <span class="gl-flex gl-items-center gl-font-bold" data-testid="job-sticky-name">
            {{ headerJob.name }}
            <job-source-badge v-if="headerJob.source" :source="headerJob.source" />
          </span>
        </div>
      </template>

      <template v-if="hasHeaderJob" #actions>
        <panel-actions-portal>
          <sidebar-header
            v-if="job.id"
            :rest-job="job"
            :job-id="job.id"
            @update-variables="onUpdateVariables"
          />
          <gl-button
            v-if="job.new_issue_path"
            v-gl-tooltip.bottom
            :href="job.new_issue_path"
            :title="$options.i18n.newIssue"
            :aria-label="$options.i18n.newIssue"
            category="tertiary"
            icon="work-item-new"
            size="small"
            data-testid="job-new-issue"
          />
          <span class="gl-border-l gl-h-5"></span>
          <gl-button
            v-gl-tooltip.bottom
            :title="$options.i18n.toggleSidebar"
            :aria-label="$options.i18n.toggleSidebar"
            category="tertiary"
            :selected="isSidebarOpen"
            icon="sidebar-right"
            size="small"
            @click="toggleSidebar"
          />
        </panel-actions-portal>
      </template>

      <template v-if="hasAlerts" #alerts>
        <gl-alert
          v-if="headerError"
          variant="danger"
          data-testid="job-header-error"
          @dismiss="headerError = null"
        >
          {{ headerError }}
        </gl-alert>
        <gl-alert v-if="shouldRenderHeaderCallout" variant="danger" :dismissible="false">
          <div v-safe-html="job.callout_message"></div>
        </gl-alert>
        <gl-alert
          v-if="shouldRenderAttestationWarning"
          :title="s__('Job|Attestation Generation Error')"
          variant="warning"
          :dismissible="false"
        >
          <div>
            {{
              s__(
                'Job|An error occurred while generating an attestation for build artifacts in this job. Please check the configuration, and try again.',
              )
            }}
          </div>
        </gl-alert>
        <gl-alert
          v-if="job.archived"
          :title="$options.i18n.archivedTitle"
          variant="info"
          :dismissible="false"
          data-testid="archived-job"
        >
          <gl-sprintf :message="$options.i18n.archivedBody">
            <template #link="{ content }">
              <gl-link :href="$options.archivedDocsPath" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </gl-alert>
      </template>

      <!-- Body Section -->
      <stuck-block
        v-if="job.stuck"
        :has-offline-runners-for-project="hasOfflineRunnersForProject"
        :tags="job.tags"
        :runners-path="runnerSettingsUrl"
      />

      <unmet-prerequisites-block
        v-if="hasUnmetPrerequisitesFailure"
        :help-path="deploymentHelpUrl"
      />

      <environments-block
        v-if="hasEnvironment"
        :deployment-status="job.deployment_status"
        :deployment-cluster="job.deployment_cluster"
        :icon-status="job.status"
      />

      <erased-block
        v-if="job.erased_at"
        data-testid="job-erased-block"
        :user="job.erased_by"
        :erased-at="job.erased_at"
      />

      <!-- job log -->
      <div v-if="hasJobLog && !showUpdateVariablesState" class="build-log-container gl-relative">
        <div :ref="observeTopBarStuck" class="job-log-top-bar-sentinel" aria-hidden="true"></div>
        <job-log-top-bar
          :class="{ 'is-stuck': isTopBarStuck }"
          :size="jobLogSize"
          :raw-path="job.raw_path"
          :log-viewer-path="logViewerPath"
          :is-scroll-bottom-disabled="isScrollBottomDisabled"
          :is-scroll-top-disabled="isScrollTopDisabled"
          :is-job-log-size-visible="isJobLogSizeVisible"
          :is-complete="isJobLogComplete"
          :job-log="jobLog"
          :full-screen-mode-available="fullScreenAPIAndContainerAvailable"
          :full-screen-enabled="fullScreenEnabled"
          @scroll-job-log-top="scrollTop"
          @scroll-job-log-bottom="scrollBottom"
          @search-results="setSearchResults"
          @enter-fullscreen="enterFullscreen"
          @exit-fullscreen="exitFullscreen"
        />

        <log :search-results="searchResults" />

        <nav
          v-if="displayStickyFooter"
          :class="[
            'rca-bar-component gl-sticky gl-z-200 gl-bg-default gl-py-3',
            { 'rca-bar-component-fullscreen': fullScreenEnabled },
          ]"
          data-testid="rca-bar-component"
        >
          <div class="gl-flex gl-w-full">
            <root-cause-analysis-button
              :job-id="job.id"
              :job-status-group="job.status.group"
              :can-troubleshoot-job="glAbilities.troubleshootJobWithAi"
            />
          </div>
        </nav>
      </div>
      <!-- EO job log -->

      <!-- job form for variables and inputs -->
      <template v-if="showJobForm">
        <template v-if="emptyStateIllustration.content">
          <h2>{{ emptyStateTitle }}</h2>

          <p data-testid="job-empty-state-content">
            {{ emptyStateIllustration.content }}
          </p>
        </template>
        <job-run-form
          :is-retryable="isJobRetryable"
          :job-id="job.id"
          :job-name="jobName"
          :confirmation-message="jobConfirmationMessage"
          @hide-manual-variables-form="onHideManualVariablesForm"
        />
      </template>
      <!-- EO job form -->

      <!-- empty state -->
      <empty-state
        v-else-if="!hasJobLog"
        :illustration-path="emptyStateIllustration.image"
        :title="emptyStateTitle"
        :confirmation-message="jobConfirmationMessage"
        :content="emptyStateIllustration.content"
        :action="emptyStateAction"
      />
      <!-- EO empty state -->
      <!-- EO Body Section -->

      <template v-if="isSidebarOpen" #sidebar>
        <sidebar :artifact-help-url="artifactHelpUrl" data-testid="job-sidebar" />
      </template>
    </detail-layout>
  </div>
</template>

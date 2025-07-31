<script>
import {
  GlTooltipDirective,
  GlButton,
  GlAvatarLink,
  GlAvatarLabeled,
  GlTooltip,
  GlLoadingIcon,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { TYPENAME_CI_BUILD } from '~/graphql_shared/constants';
import { isGid, getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import { glEmojiTag } from '~/emoji';
import { __, s__, sprintf } from '~/locale';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getJobQuery from '../graphql/queries/get_job.query.graphql';
import jobCiStatusUpdatedSubscription from '../graphql/subscriptions/job_ci_status_updated.subscription.graphql';

export default {
  components: {
    CiIcon,
    GlAvatarLabeled,
    GlAvatarLink,
    GlButton,
    GlLoadingIcon,
    GlTooltip,
    PageHeading,
    TimeagoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    projectPath: {
      default: '',
    },
  },
  props: {
    jobId: {
      type: Number,
      required: true,
    },
    user: {
      type: Object,
      required: true,
    },
  },
  apollo: {
    job: {
      query: getJobQuery,
      pollInterval() {
        return !this.shouldUseRealtimeStatus ? 30000 : null;
      },
      variables() {
        return {
          fullPath: this.projectPath,
          id: convertToGraphQLId(TYPENAME_CI_BUILD, this.jobId),
        };
      },
      update({ project }) {
        return project.job;
      },
      error(error) {
        createAlert({
          message: s__('Job|An error occurred while fetching the job header data.'),
          captureError: true,
          error,
        });
      },
      subscribeToMore: {
        document: jobCiStatusUpdatedSubscription,
        variables() {
          return {
            jobId: convertToGraphQLId(TYPENAME_CI_BUILD, this.jobId),
          };
        },
        skip() {
          // ensure we have job data before updateQuery is called
          return !this.jobId || !this.job || !this.shouldUseRealtimeStatus;
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
  data() {
    return {
      job: null,
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.job.loading;
    },
    detailedStatus() {
      return this.job?.detailedStatus || {};
    },
    shouldRenderTriggeredLabel() {
      return Boolean(this.job.startedAt);
    },
    time() {
      return this.job.startedAt || this.job.createdAt;
    },
    userAvatarAltText() {
      return sprintf(__(`%{username}'s avatar`), { username: this.user.name });
    },
    userPath() {
      // GraphQL returns `webPath` and Rest `path`
      return this.user?.webPath || this.user?.path;
    },
    avatarUrl() {
      // GraphQL returns `avatarUrl` and Rest `avatar_url`
      return this.user?.avatarUrl || this.user?.avatar_url;
    },
    webUrl() {
      // GraphQL returns `webUrl` and Rest `web_url`
      return this.user?.webUrl || this.user?.web_url;
    },
    statusTooltipHTML() {
      // Rest `status_tooltip_html` which is a ready to work
      // html for the emoji and the status text inside a tooltip.
      // GraphQL returns `status.emoji` and `status.message` which
      // needs to be combined to make the html we want.
      const { emoji } = this.user?.status || {};
      const emojiHtml = emoji ? glEmojiTag(emoji) : '';

      return emojiHtml || this.user?.status_tooltip_html;
    },
    message() {
      return this.user?.status?.message;
    },
    userId() {
      return isGid(this.user?.id) ? getIdFromGraphQLId(this.user?.id) : this.user?.id;
    },
    shouldUseRealtimeStatus() {
      return this.glFeatures?.ciJobStatusRealtime;
    },
  },
  methods: {
    onClickSidebarButton() {
      this.$emit('clickedSidebarButton');
    },
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
  EMOJI_REF: 'EMOJI_REF',
};
</script>

<template>
  <gl-loading-icon v-if="loading" class="my-5" size="lg" />
  <div v-else>
    <page-heading v-if="job" data-testid="job-header-content">
      <template #heading>
        <span data-testid="job-name">{{ job.name }}</span>
      </template>

      <template #actions>
        <gl-button
          :aria-label="__('Toggle sidebar')"
          category="secondary"
          class="gl-ml-2 lg:gl-hidden"
          icon="chevron-double-lg-left"
          @click="onClickSidebarButton"
        />
      </template>

      <template #description>
        <ci-icon class="gl-mr-1" :status="detailedStatus" show-status-text />
        <template v-if="shouldRenderTriggeredLabel">{{ __('Started') }}</template>
        <template v-else>{{ __('Created') }}</template>

        <timeago-tooltip :time="time" />

        {{ __('by') }}

        <template v-if="user">
          <gl-avatar-link
            :data-user-id="userId"
            :data-username="user.username"
            :data-name="user.name"
            :href="webUrl"
            target="_blank"
            class="js-user-link gl-mx-2 gl-items-center gl-align-middle"
          >
            <gl-avatar-labeled
              :size="24"
              :src="avatarUrl"
              :label="user.name"
              class="gl-hidden sm:gl-inline-flex"
            />
            <strong class="author gl-inline sm:gl-hidden">@{{ user.username }}</strong>
            <gl-tooltip v-if="message" :target="() => $refs[$options.EMOJI_REF]">
              {{ message }}
            </gl-tooltip>
            <span
              v-if="statusTooltipHTML"
              :ref="$options.EMOJI_REF"
              v-safe-html:[$options.safeHtmlConfig]="statusTooltipHTML"
              class="gl-ml-2"
              :data-testid="message"
            ></span>
          </gl-avatar-link>
        </template>
      </template>
    </page-heading>
  </div>
</template>

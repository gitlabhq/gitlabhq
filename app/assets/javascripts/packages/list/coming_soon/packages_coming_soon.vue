<script>
import {
  GlAlert,
  GlEmptyState,
  GlIcon,
  GlLabel,
  GlLink,
  GlSkeletonLoader,
  GlSprintf,
} from '@gitlab/ui';
import Tracking from '~/tracking';
import { TrackingActions } from '../../shared/constants';
import { s__ } from '~/locale';
import { ApolloQuery } from 'vue-apollo';
import comingSoonIssuesQuery from './queries/issues.graphql';
import { toViewModel, LABEL_NAMES } from './helpers';

export default {
  name: 'ComingSoon',
  components: {
    GlAlert,
    GlEmptyState,
    GlIcon,
    GlLabel,
    GlLink,
    GlSkeletonLoader,
    GlSprintf,
    ApolloQuery,
  },
  mixins: [Tracking.mixin()],
  props: {
    illustration: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    suggestedContributionsPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    variables() {
      return {
        projectPath: this.projectPath,
        labelNames: LABEL_NAMES,
      };
    },
  },
  mounted() {
    this.track(TrackingActions.COMING_SOON_REQUESTED);
  },
  methods: {
    onIssueLinkClick(issueIid, label) {
      this.track(TrackingActions.COMING_SOON_LIST, {
        label,
        value: issueIid,
      });
    },
    onDocsLinkClick() {
      this.track(TrackingActions.COMING_SOON_HELP);
    },
  },
  loadingRows: 5,
  i18n: {
    alertTitle: s__('PackageRegistry|Upcoming package managers'),
    alertIntro: s__(
      "PackageRegistry|Is your favorite package manager missing? We'd love your help in building first-class support for it into GitLab! %{contributionLinkStart}Visit the contribution documentation%{contributionLinkEnd} to learn more about how to build support for new package managers into GitLab. Below is a list of package managers that are on our radar.",
    ),
    emptyStateTitle: s__('PackageRegistry|No upcoming issues'),
    emptyStateDescription: s__('PackageRegistry|There are no upcoming issues to display.'),
  },
  comingSoonIssuesQuery,
  toViewModel,
};
</script>

<template>
  <apollo-query
    :query="$options.comingSoonIssuesQuery"
    :variables="variables"
    :update="$options.toViewModel"
  >
    <template #default="{ result: { data }, isLoading }">
      <div>
        <gl-alert :title="$options.i18n.alertTitle" :dismissible="false" variant="tip">
          <gl-sprintf :message="$options.i18n.alertIntro">
            <template #contributionLink="{ content }">
              <gl-link
                :href="suggestedContributionsPath"
                target="_blank"
                @click="onDocsLinkClick"
                >{{ content }}</gl-link
              >
            </template>
          </gl-sprintf>
        </gl-alert>
      </div>

      <div v-if="isLoading" class="gl-display-flex gl-flex-direction-column">
        <gl-skeleton-loader
          v-for="index in $options.loadingRows"
          :key="index"
          :width="1000"
          :height="80"
          preserve-aspect-ratio="xMinYMax meet"
        >
          <rect width="700" height="10" x="0" y="16" rx="4" />
          <rect width="60" height="10" x="0" y="45" rx="4" />
          <rect width="60" height="10" x="70" y="45" rx="4" />
        </gl-skeleton-loader>
      </div>

      <template v-else-if="data && data.length">
        <div
          v-for="issue in data"
          :key="issue.iid"
          data-testid="issue-row"
          class="gl-responsive-table-row gl-flex-direction-column gl-align-items-baseline"
        >
          <div class="table-section section-100 gl-white-space-normal text-truncate">
            <gl-link
              data-testid="issue-title-link"
              :href="issue.webUrl"
              class="gl-text-gray-900 gl-font-weight-bold"
              @click="onIssueLinkClick(issue.iid, issue.title)"
            >
              {{ issue.title }}
            </gl-link>
          </div>

          <div class="table-section section-100 gl-white-space-normal mt-md-3">
            <div class="gl-display-flex gl-text-gray-600">
              <gl-icon name="issues" class="gl-mr-2" />
              <gl-link
                data-testid="issue-id-link"
                :href="issue.webUrl"
                class="gl-text-gray-600 gl-mr-5"
                @click="onIssueLinkClick(issue.iid, issue.title)"
                >#{{ issue.iid }}</gl-link
              >

              <div v-if="issue.milestone" class="gl-display-flex gl-align-items-center gl-mr-5">
                <gl-icon name="clock" class="gl-mr-2" />
                <span data-testid="milestone">{{ issue.milestone.title }}</span>
              </div>

              <gl-label
                v-for="label in issue.labels"
                :key="label.title"
                class="gl-mr-3"
                size="sm"
                :background-color="label.color"
                :title="label.title"
                :scoped="Boolean(label.scoped)"
              />
            </div>
          </div>
        </div>
      </template>

      <gl-empty-state v-else :title="$options.i18n.emptyStateTitle" :svg-path="illustration">
        <template #description>
          <p>{{ $options.i18n.emptyStateDescription }}</p>
        </template>
      </gl-empty-state>
    </template>
  </apollo-query>
</template>

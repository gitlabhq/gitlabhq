<script>
import { GlPopover, GlSkeletonLoader } from '@gitlab/ui';
import StatusBox from '~/issuable/components/status_box.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import query from '../queries/issue.query.graphql';

export default {
  components: {
    GlPopover,
    GlSkeletonLoader,
    StatusBox,
  },
  mixins: [timeagoMixin],
  props: {
    target: {
      type: HTMLAnchorElement,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    iid: {
      type: String,
      required: true,
    },
    cachedTitle: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      issue: {},
    };
  },
  computed: {
    formattedTime() {
      return this.timeFormatted(this.issue.createdAt);
    },
    title() {
      return this.issue?.title || this.cachedTitle;
    },
    showDetails() {
      return Object.keys(this.issue).length > 0;
    },
  },
  apollo: {
    issue: {
      query,
      update: (data) => data.project.issue,
      variables() {
        const { projectPath, iid } = this;

        return {
          projectPath,
          iid,
        };
      },
    },
  },
};
</script>

<template>
  <gl-popover :target="target" boundary="viewport" placement="top" show>
    <gl-skeleton-loader v-if="$apollo.queries.issue.loading" :height="15">
      <rect width="250" height="15" rx="4" />
    </gl-skeleton-loader>
    <div v-else-if="showDetails" class="gl-display-flex gl-align-items-center">
      <status-box issuable-type="issue" :initial-state="issue.state" />
      <span class="gl-text-secondary">
        {{ __('Opened') }} <time :datetime="issue.createdAt">{{ formattedTime }}</time>
      </span>
    </div>
    <h5 v-if="!$apollo.queries.issue.loading" class="gl-my-3">{{ title }}</h5>
    <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
    <div class="gl-text-secondary">
      {{ `${projectPath}#${iid}` }}
    </div>
    <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
  </gl-popover>
</template>

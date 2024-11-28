<script>
import { GlBadge, GlPopover, GlSkeletonLoader } from '@gitlab/ui';
import { STATUS_CLOSED, STATUS_MERGED } from '~/issues/constants';
import { __ } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import query from '../queries/merge_request.query.graphql';

export default {
  components: {
    GlBadge,
    GlPopover,
    GlSkeletonLoader,
    CiIcon,
  },
  mixins: [timeagoMixin],
  props: {
    target: {
      type: HTMLAnchorElement,
      required: true,
    },
    namespacePath: {
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
      mergeRequest: {},
    };
  },
  computed: {
    detailedStatus() {
      return this.mergeRequest.headPipeline && this.mergeRequest.headPipeline.detailedStatus;
    },
    formattedTime() {
      return this.timeFormatted(this.mergeRequest.createdAt);
    },
    badgeVariant() {
      switch (this.mergeRequest.state) {
        case STATUS_MERGED:
          return 'info';
        case STATUS_CLOSED:
          return 'danger';
        default:
          return 'success';
      }
    },
    stateHumanName() {
      switch (this.mergeRequest.state) {
        case STATUS_MERGED:
          return __('Merged');
        case STATUS_CLOSED:
          return __('Closed');
        default:
          return __('Open');
      }
    },
    title() {
      return this.mergeRequest?.title || this.cachedTitle;
    },
    showDetails() {
      return Object.keys(this.mergeRequest).length > 0;
    },
  },
  apollo: {
    mergeRequest: {
      query,
      update: (data) => data.project?.mergeRequest || {},
      variables() {
        const { namespacePath, iid } = this;

        return {
          projectPath: namespacePath,
          iid,
        };
      },
    },
  },
};
</script>

<template>
  <gl-popover :target="target" boundary="viewport" placement="top" show>
    <div class="mr-popover">
      <gl-skeleton-loader v-if="$apollo.queries.mergeRequest.loading" :height="15">
        <rect width="250" height="15" rx="4" />
      </gl-skeleton-loader>
      <div v-else-if="showDetails" class="gl-flex gl-items-center gl-justify-between">
        <div class="gl-inline-flex gl-items-center">
          <gl-badge class="gl-mr-2" :variant="badgeVariant">
            {{ stateHumanName }}
          </gl-badge>
          <span class="gl-text-subtle">
            {{ __('Opened') }} <time v-text="formattedTime"></time
          ></span>
        </div>
        <ci-icon v-if="detailedStatus" :status="detailedStatus" class="gl-ml-2" />
      </div>
      <h5 v-if="!$apollo.queries.mergeRequest.loading" class="my-2">{{ title }}</h5>
      <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
      <div class="gl-text-subtle">
        {{ `${namespacePath}!${iid}` }}
      </div>
      <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
    </div>
  </gl-popover>
</template>

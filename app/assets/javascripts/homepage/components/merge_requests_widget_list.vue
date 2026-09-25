<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import { mergeRequestsDashboardPath } from '~/lib/utils/path_helpers/dashboard';
import { InternalEvents } from '~/tracking';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_MERGE_REQUESTS_WIDGET,
  TRACKING_PROPERTY_ALL_MERGE_REQUESTS,
} from '../tracking_constants';
import MergeRequestItem from './merge_request_item.vue';

const N_COLLAPSED = 4;

export default {
  name: 'MergeRequestsWidgetList',
  components: {
    GlButton,
    MergeRequestItem,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    mergeRequests: {
      type: Array,
      required: true,
    },
    emptyText: {
      type: String,
      required: true,
    },
    trackingProperty: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isExpanded: false,
    };
  },
  computed: {
    visibleMergeRequests() {
      return this.isExpanded ? this.mergeRequests : this.mergeRequests.slice(0, N_COLLAPSED);
    },
    hasToggle() {
      return this.mergeRequests.length > N_COLLAPSED;
    },
    toggleText() {
      return this.isExpanded ? __('Show less') : __('Show more');
    },
    dashboardPath() {
      return mergeRequestsDashboardPath();
    },
  },
  methods: {
    trackLinkClick(property) {
      this.trackEvent(EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE, {
        label: TRACKING_LABEL_MERGE_REQUESTS_WIDGET,
        property,
      });
    },
    trackDashboardClick() {
      this.trackLinkClick(TRACKING_PROPERTY_ALL_MERGE_REQUESTS);
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-gap-4">
    <p v-if="!mergeRequests.length" class="gl-mb-0 gl-text-subtle" data-testid="empty-state">
      {{ emptyText }}
    </p>

    <ul v-else class="gl-m-0 gl-flex gl-list-none gl-flex-col gl-gap-4 gl-p-0">
      <li v-for="mergeRequest in visibleMergeRequests" :key="mergeRequest.id">
        <merge-request-item
          :merge-request="mergeRequest"
          @click="trackLinkClick(trackingProperty)"
        />
      </li>
    </ul>

    <div class="gl-flex gl-items-center gl-justify-between gl-gap-3">
      <gl-button
        v-if="hasToggle"
        variant="link"
        data-testid="toggle-button"
        @click="isExpanded = !isExpanded"
      >
        {{ toggleText }}
      </gl-button>
      <a :href="dashboardPath" class="gl-ml-auto" @click="trackDashboardClick">
        {{ __('All merge requests') }}
      </a>
    </div>
  </div>
</template>

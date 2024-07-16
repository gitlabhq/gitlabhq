<script>
import { GlBadge, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getUserFollowers } from '~/rest_api';
import { createAlert } from '~/alert';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import Follow from './follow.vue';

export default {
  i18n: {
    title: s__('UserProfile|Followers'),
    errorMessage: s__(
      'UserProfile|An error occurred loading the followers. Please refresh the page to try again.',
    ),
    currentUserEmptyStateTitle: s__('UserProfile|You do not have any followers'),
    visitorEmptyStateTitle: s__("UserProfile|This user doesn't have any followers"),
  },
  components: {
    GlBadge,
    GlTab,
    Follow,
  },
  inject: ['followersCount', 'userId'],
  data() {
    return {
      followers: [],
      loading: true,
      totalItems: 0,
      page: 1,
    };
  },
  watch: {
    page: {
      async handler() {
        this.loading = true;

        try {
          const { data: followers, headers } = await getUserFollowers(this.userId, {
            page: this.page,
          });
          const { total } = parseIntPagination(normalizeHeaders(headers));

          this.followers = followers;
          this.totalItems = total;
        } catch (error) {
          createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
        } finally {
          this.loading = false;
        }
      },
      immediate: true,
    },
  },
  methods: {
    onPaginationInput(page) {
      this.page = page;
    },
  },
};
</script>

<template>
  <gl-tab>
    <template #title>
      <span>{{ $options.i18n.title }}</span>
      <gl-badge class="gl-ml-2">{{ followersCount }}</gl-badge>
    </template>
    <follow
      :users="followers"
      :loading="loading"
      :page="page"
      :total-items="totalItems"
      :current-user-empty-state-title="$options.i18n.currentUserEmptyStateTitle"
      :visitor-empty-state-title="$options.i18n.visitorEmptyStateTitle"
      @pagination-input="onPaginationInput"
    />
  </gl-tab>
</template>

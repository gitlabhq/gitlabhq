<script>
import { GlBadge, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getUserFollowing } from '~/rest_api';
import { createAlert } from '~/alert';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import Follow from './follow.vue';

export default {
  i18n: {
    title: s__('UserProfile|Following'),
    errorMessage: s__(
      'UserProfile|An error occurred loading the following. Please refresh the page to try again.',
    ),
    currentUserEmptyStateTitle: s__('UserProfile|You are not following other users'),
    visitorEmptyStateTitle: s__("UserProfile|This user isn't following other users"),
  },
  components: {
    GlBadge,
    GlTab,
    Follow,
  },
  inject: ['followeesCount', 'userId'],
  data() {
    return {
      following: [],
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
          const { data: following, headers } = await getUserFollowing(this.userId, {
            page: this.page,
          });

          const { total } = parseIntPagination(normalizeHeaders(headers));

          this.following = following;
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
      <gl-badge class="gl-ml-2">{{ followeesCount }}</gl-badge>
    </template>
    <follow
      :users="following"
      :loading="loading"
      :page="page"
      :total-items="totalItems"
      :current-user-empty-state-title="$options.i18n.currentUserEmptyStateTitle"
      :visitor-empty-state-title="$options.i18n.visitorEmptyStateTitle"
      @pagination-input="onPaginationInput"
    />
  </gl-tab>
</template>

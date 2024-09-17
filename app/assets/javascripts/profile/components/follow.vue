<!-- eslint-disable vue/multi-word-component-names -->
<script>
import {
  GlAvatarLabeled,
  GlAvatarLink,
  GlLoadingIcon,
  GlPagination,
  GlEmptyState,
} from '@gitlab/ui';
import { DEFAULT_PER_PAGE } from '~/api';
import { isCurrentUser } from '~/lib/utils/common_utils';

export default {
  components: {
    GlAvatarLabeled,
    GlAvatarLink,
    GlLoadingIcon,
    GlPagination,
    GlEmptyState,
  },
  inject: ['followEmptyState', 'userId'],
  props: {
    /**
     * Expected format:
     *
     * {
     *   avatar_url: string;
     *   id: number;
     *   name: string;
     *   state: string;
     *   username: string;
     *   web_url: string;
     * }[]
     */
    users: {
      type: Array,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
    page: {
      type: Number,
      required: true,
    },
    totalItems: {
      type: Number,
      required: true,
    },
    perPage: {
      type: Number,
      required: false,
      default: DEFAULT_PER_PAGE,
    },
    currentUserEmptyStateTitle: {
      type: String,
      required: true,
    },
    visitorEmptyStateTitle: {
      type: String,
      required: true,
    },
  },
  computed: {
    emptyStateTitle() {
      return isCurrentUser(this.userId)
        ? this.currentUserEmptyStateTitle
        : this.visitorEmptyStateTitle;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="loading" class="gl-mt-5" size="md" />
  <gl-empty-state
    v-else-if="!users.length"
    class="gl-mt-5"
    :svg-path="followEmptyState"
    :svg-height="144"
    :title="emptyStateTitle"
  />
  <div v-else>
    <div class="-gl-mx-3 -gl-my-3 gl-flex gl-flex-wrap">
      <div v-for="user in users" :key="user.id" class="gl-w-full gl-p-3 md:gl-w-1/2 lg:gl-w-1/4">
        <gl-avatar-link
          :href="user.web_url"
          class="js-user-link gl-border gl-w-full gl-rounded-base gl-p-5"
          :data-user-id="user.id"
          :data-username="user.username"
        >
          <gl-avatar-labeled
            :src="user.avatar_url"
            :size="48"
            :entity-id="user.id"
            :entity-name="user.name"
            :label="user.name"
            :sub-label="user.username"
          />
        </gl-avatar-link>
      </div>
    </div>
    <gl-pagination
      align="center"
      class="gl-mt-5"
      :value="page"
      :total-items="totalItems"
      :per-page="perPage"
      @input="$emit('pagination-input', $event)"
    />
  </div>
</template>

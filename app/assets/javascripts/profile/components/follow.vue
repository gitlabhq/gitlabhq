<script>
import { GlAvatarLabeled, GlAvatarLink, GlLoadingIcon, GlPagination } from '@gitlab/ui';
import { DEFAULT_PER_PAGE } from '~/api';
import { NEXT, PREV } from '~/vue_shared/components/pagination/constants';

export default {
  i18n: {
    prev: PREV,
    next: NEXT,
  },
  components: {
    GlAvatarLabeled,
    GlAvatarLink,
    GlLoadingIcon,
    GlPagination,
  },
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
  },
};
</script>

<template>
  <gl-loading-icon v-if="loading" class="gl-mt-5" size="md" />
  <div v-else>
    <div class="gl-my-n3 gl-mx-n3 gl-display-flex gl-flex-wrap">
      <div v-for="user in users" :key="user.id" class="gl-p-3 gl-w-full gl-md-w-half gl-lg-w-25p">
        <gl-avatar-link
          :href="user.web_url"
          class="js-user-link gl-border gl-rounded-base gl-w-full gl-p-5"
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
      :prev-text="$options.i18n.prev"
      :next-text="$options.i18n.next"
      @input="$emit('pagination-input', $event)"
    />
  </div>
</template>

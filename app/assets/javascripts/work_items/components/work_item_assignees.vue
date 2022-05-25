<script>
import { GlAvatar, GlLink } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export default {
  components: {
    GlAvatar,
    GlLink,
  },
  props: {
    assignees: {
      type: Array,
      required: true,
    },
  },
  methods: {
    getUserId(id) {
      return getIdFromGraphQLId(id);
    },
  },
};
</script>

<template>
  <div class="gl-display-flex">
    <span class="gl-font-weight-bold gl-w-15 gl-pt-1">{{ __('Assignee(s)') }}</span>
    <div class="gl-mb-4">
      <gl-link
        v-for="user in assignees"
        :key="user.id"
        :href="user.webUrl"
        :title="`test`"
        :data-user-id="getUserId(user.id)"
        data-placement="top"
        class="gl-text-decoration-none! gl-text-black-normal! gl-display-flex gl-md-display-inline-flex! gl-align-items-center gl-mb-4 gl-md-mb-0 gl-mr-4 js-user-link"
      >
        <gl-avatar :size="24" :src="user.avatarUrl" />
        <span class="gl-pl-2">{{ user.name }}</span>
      </gl-link>
    </div>
  </div>
</template>

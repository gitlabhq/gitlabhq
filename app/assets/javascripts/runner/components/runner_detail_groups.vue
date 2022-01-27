<script>
import { GlAvatar, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlAvatar,
    GlLink,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  computed: {
    groups() {
      return this.runner.groups?.nodes || [];
    },
  },
};
</script>

<template>
  <div class="gl-border-t-gray-100 gl-border-t-1 gl-border-t-solid">
    <h3 class="gl-font-lg gl-my-5">{{ s__('Runners|Assigned Group') }}</h3>
    <template v-if="groups.length">
      <div v-for="group in groups" :key="group.id" class="gl-display-flex gl-align-items-center">
        <gl-link
          :href="group.webUrl"
          data-testid="group-avatar"
          class="gl-text-decoration-none! gl-mr-3"
        >
          <gl-avatar
            shape="rect"
            :entity-name="group.name"
            :src="group.avatarUrl"
            :alt="group.name"
            :size="48"
          />
        </gl-link>

        <gl-link :href="group.webUrl" class="gl-font-lg gl-font-weight-bold gl-text-gray-900!">{{
          group.fullName
        }}</gl-link>
      </div>
    </template>
    <span v-else class="gl-text-gray-500">{{ __('None') }}</span>
  </div>
</template>

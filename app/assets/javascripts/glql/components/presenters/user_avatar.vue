<script>
import { GlAvatarLabeled, GlAvatarLink } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export default {
  name: 'UserAvatarPresenter',
  components: {
    GlAvatarLabeled,
    GlAvatarLink,
  },
  props: {
    data: {
      required: true,
      type: Object,
    },
  },
  computed: {
    entityId() {
      return getIdFromGraphQLId(this.data.id);
    },
  },
};
</script>
<template>
  <!-- Fixing this for every webUrl usage in GLQL in: https://gitlab.com/gitlab-org/glql/-/work_items/126 -->
  <!-- eslint-disable-next-line local-rules/vue-no-web-url -->
  <gl-avatar-link :href="data.webUrl">
    <gl-avatar-labeled
      :label="data.name"
      :sub-label="`@${data.username}`"
      :src="data.avatarUrl"
      :alt="data.name"
      :size="32"
      :entity-name="data.name"
      :entity-id="entityId"
    />
  </gl-avatar-link>
</template>

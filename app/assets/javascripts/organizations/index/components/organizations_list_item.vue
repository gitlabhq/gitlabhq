<script>
import { GlAvatarLabeled } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export default {
  name: 'OrganizationsListItem',
  components: {
    GlAvatarLabeled,
  },
  props: {
    organization: {
      type: Object,
      required: true,
    },
  },
  avatarSize: { default: 32, md: 48 },
  getIdFromGraphQLId,
};
</script>

<template>
  <li class="gl-py-3 gl-border-b gl-display-flex gl-align-items-flex-start">
    <gl-avatar-labeled
      :size="$options.avatarSize"
      :src="organization.avatarUrl"
      :entity-id="$options.getIdFromGraphQLId(organization.id)"
      :entity-name="organization.name"
      :label="organization.name"
      :label-link="organization.webUrl"
      shape="rect"
    >
      <span class="gl-mt-2 gl-text-gray-500">{{ organization.description }}</span>
    </gl-avatar-labeled>
  </li>
</template>

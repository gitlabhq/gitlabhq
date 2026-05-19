<script>
import { GlAvatarLabeled, GlCard } from '@gitlab/ui';
import gitlabLogoUrl from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg?url';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEFAULT_ORGANIZATION_NAME } from '~/organizations/shared/constants';
import { isDefaultOrganization } from '~/organizations/shared/utils';

export default {
  name: 'OrganizationCard',
  AVATAR_SHAPE_OPTION_RECT,
  components: {
    GlAvatarLabeled,
    GlCard,
  },
  props: {
    organization: {
      type: Object,
      required: true,
    },
  },
  computed: {
    organizationName() {
      if (isDefaultOrganization(this.organization)) {
        return DEFAULT_ORGANIZATION_NAME;
      }

      return this.organization.name;
    },
    organizationAvatarUrl() {
      if (isDefaultOrganization(this.organization)) {
        return gitlabLogoUrl;
      }

      return this.organization.avatarUrl;
    },
    bodyClass() {
      const baseClasses = ['gl-bg-transparent'];

      if (this.$scopedSlots.default) {
        return baseClasses;
      }

      return [...baseClasses, 'gl-hidden'];
    },
    headerClass() {
      return {
        'gl-pb-2': !this.$scopedSlots.default,
      };
    },
  },
  methods: {
    getIdFromGraphQLId,
  },
};
</script>

<template>
  <gl-card class="gl-h-full" :header-class="headerClass" :body-class="bodyClass">
    <template #header>
      <gl-avatar-labeled
        class="gl-flex"
        :label="organizationName"
        :entity-id="getIdFromGraphQLId(organization.id)"
        :entity-name="organizationName"
        :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        :size="32"
        :src="organizationAvatarUrl"
      />
    </template>
    <div class="gl-relative gl-h-full">
      <slot></slot>
    </div>
  </gl-card>
</template>

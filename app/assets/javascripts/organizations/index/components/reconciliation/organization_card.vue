<script>
import { GlAvatarLabeled, GlCard, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import gitlabLogoUrl from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg?url';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEFAULT_ORGANIZATION_NAME } from '~/organizations/shared/constants';
import { VISIBILITY_TYPE_ICON, ORGANIZATION_VISIBILITY_TYPE } from '~/visibility_level/constants';
import { isDefaultOrganization } from '~/organizations/shared/utils';

export default {
  name: 'OrganizationCard',
  AVATAR_SHAPE_OPTION_RECT,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlAvatarLabeled,
    GlCard,
    GlIcon,
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
    visibility() {
      return this.organization.visibility;
    },
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.visibility];
    },
    visibilityTooltip() {
      return ORGANIZATION_VISIBILITY_TYPE[this.visibility];
    },
  },
  methods: {
    getIdFromGraphQLId,
    isDefaultOrganization,
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
      >
        <template v-if="!isDefaultOrganization(organization)" #meta>
          <div class="gl-p-1">
            <gl-icon
              v-gl-tooltip="visibilityTooltip"
              :name="visibilityIcon"
              variant="subtle"
              data-testid="organization-visibility"
            />
          </div>
        </template>
      </gl-avatar-labeled>
    </template>
    <div class="gl-relative gl-h-full">
      <slot></slot>
    </div>
  </gl-card>
</template>

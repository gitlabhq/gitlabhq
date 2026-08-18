<script>
import { GlAvatarLabeled, GlCard, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { VISIBILITY_TYPE_ICON, ORGANIZATION_VISIBILITY_TYPE } from '~/visibility_level/constants';
import { isDefaultOrganization } from '~/organizations/shared/utils';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

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
  mixins: [glSlotsMixin],
  props: {
    organization: {
      type: Object,
      required: true,
    },
  },
  computed: {
    organizationName() {
      return this.organization.name;
    },
    organizationAvatarUrl() {
      return this.organization.avatarUrl;
    },
    bodyClass() {
      const baseClasses = ['gl-bg-transparent'];

      if (this.glSlots().default) {
        return baseClasses;
      }

      return [...baseClasses, 'gl-hidden'];
    },
    headerClass() {
      return {
        'gl-pb-2': !this.glSlots().default,
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
    isDefaultOrganization() {
      return isDefaultOrganization(this.organization);
    },
  },
  methods: {
    getIdFromGraphQLId,
  },
};
</script>

<template>
  <gl-card
    v-if="isDefaultOrganization"
    class="gl-border gl-h-full gl-bg-transparent"
    :header-class="headerClass"
    :body-class="bodyClass"
  >
    <template #header>
      <div class="gl-pt-3 gl-text-center">
        <p class="gl-m-0 gl-text-sm">{{ s__('Organization|Other top-level groups') }}</p>
      </div>
    </template>
    <div class="gl-relative gl-h-full">
      <slot :is-default-organization="true"></slot>
    </div>
  </gl-card>
  <gl-card v-else class="gl-h-full" :header-class="headerClass" :body-class="bodyClass">
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
        <template #meta>
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
      <slot :is-default-organization="false"></slot>
    </div>
  </gl-card>
</template>

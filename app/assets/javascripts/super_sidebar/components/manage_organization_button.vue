<script>
import { GlNavItem, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'ManageOrganizationButton',
  components: { GlNavItem },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['isIconOnly'],
  props: {
    href: {
      type: String,
      required: true,
    },
    isExit: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    text() {
      return this.isExit
        ? s__('Organization|Back to organization')
        : s__('Organization|Manage organization');
    },
    icon() {
      return this.isExit ? 'go-back' : 'admin';
    },
  },
};
</script>

<template>
  <gl-nav-item
    v-gl-tooltip.right="isIconOnly ? text : ''"
    :is-icon-only="isIconOnly"
    :href="href"
    :icon="icon"
    :aria-label="text"
    data-testid="manage-organization-button"
  >
    {{ text }}
  </gl-nav-item>
</template>

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
  },
  i18n: {
    text: s__('Organization|Manage organization'),
  },
};
</script>

<template>
  <gl-nav-item
    v-gl-tooltip.right="isIconOnly ? $options.i18n.text : ''"
    :is-icon-only="isIconOnly"
    :href="href"
    icon="admin"
    :aria-label="$options.i18n.text"
    data-testid="manage-organization-button"
  >
    {{ $options.i18n.text }}
  </gl-nav-item>
</template>

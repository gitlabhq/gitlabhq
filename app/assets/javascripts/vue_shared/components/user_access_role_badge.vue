<script>
/**
 * This component applies particular styling to GlBadge that isn't
 * available in the current GlBadge variants.
 * Where possible, prefer one of the supported GlBadge variants.
 * Discussion issue: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1247 [CLOSED]
 */
import { GlBadge } from '@gitlab/ui';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

export default {
  name: 'UserAccessRoleBadge',
  components: {
    GlBadge,
  },
  mixins: [glSlotsMixin],
};
</script>

<template>
  <gl-badge variant="neutral">
    <template v-if="glSlots().default" #default><slot></slot></template>
  </gl-badge>
</template>

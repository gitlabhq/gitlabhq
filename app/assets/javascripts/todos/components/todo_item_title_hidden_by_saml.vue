<script>
import { GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlBadge,
  },
  props: {},
  i18n: {
    hiddenTodoTitle: s__('Todos|Select this item to sign in with SAML and view it.'),
    hiddenTodoBadgeText: s__('Todos|Hidden'),
  },
};
</script>

<template>
  <div>
    <gl-badge
      variant="warning"
      icon="eye-slash"
      :aria-label="$options.i18n.hiddenTodoBadgeText"
      class="gl-shrink-0"
    >
      {{ $options.i18n.hiddenTodoBadgeText }}
    </gl-badge>
    <div class="gl-overflow-hidden gl-text-ellipsis" data-testid="todo-title">
      {{ $options.i18n.hiddenTodoTitle }}
    </div>
  </div>
</template>

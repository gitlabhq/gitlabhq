<script>
import { GlButton, GlEmptyState } from '@gitlab/ui';

export default {
  name: 'JobEmptyState',
  components: {
    GlButton,
    GlEmptyState,
  },
  props: {
    illustrationPath: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    content: {
      type: String,
      required: false,
      default: null,
    },
    action: {
      type: Object,
      required: false,
      default: null,
      validator(value) {
        return (
          value === null ||
          (Object.prototype.hasOwnProperty.call(value, 'path') &&
            Object.prototype.hasOwnProperty.call(value, 'method') &&
            Object.prototype.hasOwnProperty.call(value, 'button_title'))
        );
      },
    },
  },
};
</script>
<template>
  <gl-empty-state :title="title" :svg-path="illustrationPath">
    <template #description>
      <p v-if="content" class="gl-mb-0 gl-mt-4" data-testid="job-empty-state-content">
        {{ content }}
      </p>
    </template>
    <template v-if="action" #actions>
      <gl-button
        :href="action.path"
        :data-method="action.method"
        variant="confirm"
        data-testid="job-empty-state-action"
      >
        {{ action.button_title }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>

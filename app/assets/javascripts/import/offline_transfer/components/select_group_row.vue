<script>
import { GlAvatar, GlFormCheckbox } from '@gitlab/ui';

export default {
  name: 'SelectGroupRow',
  components: { GlAvatar, GlFormCheckbox },
  props: {
    name: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
    avatarUrl: {
      type: String,
      required: false,
      default: null,
    },
    checked: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['toggle'],
};
</script>
<template>
  <li
    class="gl-border-t gl-flex gl-cursor-pointer gl-items-center gl-gap-3 gl-py-3"
    data-testid="select-group-row"
    @click="$emit('toggle')"
  >
    <gl-form-checkbox
      class="gl-pointer-events-none gl-mt-1 gl-pt-2"
      :checked="checked"
      :aria-label="name"
    />
    <gl-avatar
      :fallback-on-error="true"
      :entity-name="name"
      :src="avatarUrl"
      :size="32"
      shape="rect"
    />
    <div class="gl-min-w-0 gl-pl-2">
      <p class="gl-heading-5 gl-mb-0">{{ name }}</p>
      <p
        v-if="description"
        class="gl-mb-0 gl-mt-2 gl-truncate gl-text-sm gl-leading-1 gl-text-tertiary"
      >
        {{ description }}
      </p>
    </div>
  </li>
</template>

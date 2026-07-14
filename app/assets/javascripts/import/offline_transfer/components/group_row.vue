<script>
import { GlAvatar, GlFormCheckbox } from '@gitlab/ui';

export default {
  name: 'GroupRow',
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
    selectable: {
      type: Boolean,
      required: false,
      default: false,
    },
    checked: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['toggle'],
  methods: {
    onClick() {
      if (this.selectable) {
        this.$emit('toggle');
      }
    },
  },
};
</script>
<template>
  <li
    class="gl-border-t gl-flex gl-items-center gl-gap-3 gl-py-3"
    :class="{ 'gl-cursor-pointer': selectable }"
    data-testid="group-row"
    @click="onClick"
  >
    <gl-form-checkbox
      v-if="selectable"
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

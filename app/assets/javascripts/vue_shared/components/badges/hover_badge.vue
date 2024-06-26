<script>
import { GlBadge, GlPopover } from '@gitlab/ui';

export default {
  name: 'HoverBadge',
  components: { GlBadge, GlPopover },
  props: {
    label: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
  },
  methods: {
    target() {
      /**
       * BVPopover retrieves the target during the `beforeDestroy` hook to deregister attached
       * events. Since during `beforeDestroy` refs are `undefined`, it throws a warning in the
       * console because we're trying to access the `$el` property of `undefined`. Optional
       * chaining is not working in templates, which is why the method is used.
       *
       * See more on https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49628#note_464803276
       */
      return this.$refs.badge?.$el;
    },
  },
};
</script>

<template>
  <div>
    <gl-badge ref="badge" href="#" variant="neutral" class="gl-cursor-pointer">{{
      label
    }}</gl-badge>
    <gl-popover
      triggers="hover focus click"
      :show-close-button="true"
      :target="target"
      :title="title"
    >
      <slot></slot>
    </gl-popover>
  </div>
</template>

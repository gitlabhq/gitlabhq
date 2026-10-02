<script>
import { GlPopover, GlSprintf, GlLink } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';

export default {
  name: 'LockPopover',
  components: {
    GlPopover,
    GlSprintf,
    GlLink,
  },
  props: {
    ancestorNamespace: {
      type: Object,
      required: false,
      default: null,
      validator: (value) => Boolean(value?.path) && Boolean(value?.fullName),
    },
    isLockedByAdmin: {
      type: Boolean,
      required: true,
    },
    isLockedByGroupAncestor: {
      type: Boolean,
      required: true,
    },
    targetElement: {
      type: Element,
      required: true,
    },
  },
  data() {
    return {
      containerId: uniqueId('cascading-settings-lock-popover-'),
    };
  },
  computed: {
    isLocked() {
      return this.isLockedByAdmin || this.isLockedByGroupAncestor;
    },
  },
};
</script>

<template>
  <span v-if="isLocked" :id="containerId">
    <gl-popover
      :target="targetElement"
      :container="containerId"
      triggers="hover focus"
      placement="top"
    >
      <template #title>{{ s__('CascadingSettings|Setting cannot be changed') }}</template>
      <span data-testid="cascading-settings-lock-popover">
        <template v-if="isLockedByAdmin">{{
          s__(
            'CascadingSettings|An administrator selected this setting for the instance and you cannot change it.',
          )
        }}</template>
        <gl-sprintf
          v-else-if="isLockedByGroupAncestor && ancestorNamespace"
          :message="s__('CascadingSettings|This setting has been enforced by an owner of %{link}.')"
        >
          <template #link>
            <gl-link :href="ancestorNamespace.path" class="gl-text-sm">{{
              ancestorNamespace.fullName
            }}</gl-link>
          </template>
        </gl-sprintf>
        <template v-else>
          {{
            s__(
              'CascadingSettings|This setting has been enforced by an owner and cannot be changed.',
            )
          }}
        </template>
      </span>
    </gl-popover>
  </span>
</template>

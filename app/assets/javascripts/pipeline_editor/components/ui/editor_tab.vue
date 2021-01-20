<script>
import { GlTab } from '@gitlab/ui';

/**
 * Wrapper of <gl-tab> to optionally lazily render this tab's content
 * when its shown **without dismounting after its hidden**.
 *
 * Usage:
 *
 * API is the same as <gl-tab>, for example:
 *
 * <gl-tabs>
 *   <editor-tab title="Tab 1" :lazy="true">
 *     lazily mounted content (gets mounted if this is first tab)
 *   </editor-tab>
 *   <editor-tab title="Tab 2" :lazy="true">
 *     lazily mounted content
 *   </editor-tab>
 *   <editor-tab title="Tab 3">
 *      eagerly mounted content
 *   </editor-tab>
 * </gl-tabs>
 *
 * Once the tab is selected it is permanently set as "not-lazy"
 * so it's contents are not dismounted.
 *
 * lazy is "false" by default, as in <gl-tab>.
 */

export default {
  components: {
    GlTab,
    // Use a small renderless component to know when the tab content mounts because:
    // - gl-tab always gets mounted, even if lazy is `true`. See:
    // https://github.com/bootstrap-vue/bootstrap-vue/blob/dev/src/components/tabs/tab.js#L180
    // - we cannot listen to events on <slot />
    MountSpy: {
      render: () => null,
    },
  },
  inheritAttrs: false,
  props: {
    lazy: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isLazy: this.lazy,
    };
  },
  methods: {
    onContentMounted() {
      // When a child is first mounted make the entire tab
      // permanently mounted by setting 'lazy' to false.
      this.isLazy = false;
    },
  },
};
</script>
<template>
  <gl-tab :lazy="isLazy" v-bind="$attrs" v-on="$listeners">
    <slot v-for="slot in Object.keys($slots)" :slot="slot" :name="slot"></slot>
    <mount-spy @hook:mounted="onContentMounted" />
  </gl-tab>
</template>

<script>
import { GlAlert, GlBadge, GlTab } from '@gitlab/ui';
import { __, s__ } from '~/locale';
/**
 * Wrapper of <gl-tab> to optionally lazily render this tab's content
 * when its shown **without dismounting after its hidden**.
 *
 * Usage:
 *
 * API is the same as <gl-tab>, for example:
 *
 * <gl-tabs>
 *   <editor-tab title="Tab 1" lazy>
 *     lazily mounted content (gets mounted if this is first tab)
 *   </editor-tab>
 *   <editor-tab title="Tab 2" lazy>
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
 *
 * It is also possible to pass the `isEmpty` and or `isInvalid` to let
 * the tab component handle that state on its own. For example:
 *
 *  * <gl-tabs>
 *   <editor-tab-with-status title="Tab 1" :is-empty="isEmpty" :is-invalid="isInvalid">
 *    ...
 *   </editor-tab-with-status>
 *   Will be the same as normal, except it will only render the slot component
 *   if the status is not empty and not invalid. In any of these 2 cases, it will render
 *   a generic component and avoid mounting whatever it received in the slot.
 * </gl-tabs>
 */

export default {
  i18n: {
    invalid: __(
      'Your CI/CD configuration syntax is invalid. Select the Validate tab for more details.',
    ),
    unavailable: __(
      "We're experiencing difficulties and this tab content is currently unavailable.",
    ),
  },
  components: {
    GlAlert,
    GlBadge,
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
    badgeTitle: {
      type: String,
      required: false,
      default: '',
    },
    badgeVariant: {
      type: String,
      required: false,
      default: 'info',
    },
    emptyMessage: {
      type: String,
      required: false,
      default: s__(
        'PipelineEditor|This tab will be usable when the CI/CD configuration file is populated with valid syntax.',
      ),
    },
    isEmpty: {
      type: Boolean,
      required: false,
      default: false,
    },
    isInvalid: {
      type: Boolean,
      required: false,
      default: false,
    },
    isUnavailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    keepComponentMounted: {
      type: Boolean,
      required: false,
      default: true,
    },
    lazy: {
      type: Boolean,
      required: false,
      default: false,
    },
    title: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isLazy: this.lazy,
    };
  },
  computed: {
    hasBadgeTitle() {
      return this.badgeTitle.length > 0;
    },
    slots() {
      // eslint-disable-next-line @gitlab/vue-prefer-dollar-scopedslots
      return Object.keys(this.$slots);
    },
  },
  methods: {
    onContentMounted() {
      // When a child is first mounted make the entire tab
      // permanently mounted by setting 'lazy' to false unless
      // explicitly opted out.
      if (this.keepComponentMounted) {
        this.isLazy = false;
      }
    },
  },
};
</script>
<template>
  <gl-tab :lazy="isLazy" v-bind="$attrs" v-on="$listeners">
    <template #title>
      <span>{{ title }}</span>
      <gl-badge v-if="hasBadgeTitle" class="gl-ml-2" :variant="badgeVariant">{{
        badgeTitle
      }}</gl-badge>
    </template>
    <gl-alert v-if="isEmpty" variant="tip">{{ emptyMessage }}</gl-alert>
    <gl-alert v-else-if="isUnavailable" variant="danger" :dismissible="false">
      {{ $options.i18n.unavailable }}</gl-alert
    >
    <gl-alert v-else-if="isInvalid" variant="danger">{{ $options.i18n.invalid }}</gl-alert>
    <template v-else>
      <slot v-for="slot in slots" :name="slot"></slot>
      <mount-spy @hook:mounted="onContentMounted" />
    </template>
  </gl-tab>
</template>

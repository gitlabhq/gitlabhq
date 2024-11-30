<!-- eslint-disable vue/multi-word-component-names -->
<script>
import iconSpriteInfo from '@gitlab/svgs/dist/icons.json';
import { GlIcon, GlLink } from '@gitlab/ui';
import { ISSUABLE_EPIC } from '../../constants';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    /**
     * Path item in the form:
     * ```
     * {
     *   title:    String, required
     *   icon:     String, optional
     *   ancestorNotAvailable: Boolean, optional
     * }
     * ```
     */
    item: {
      type: Object,
      required: false,
      default: () => {},
    },
    itemId: {
      type: String,
      required: false,
      default: null,
    },
  },
  methods: {
    shouldDisplayIcon(icon) {
      if (icon === ISSUABLE_EPIC) return true;
      return icon && iconSpriteInfo.icons.includes(icon);
    },
  },
};
</script>

<template>
  <li class="disclosure-hierarchy-item gl-flex gl-min-w-0">
    <gl-link
      :id="itemId"
      :href="item.webUrl"
      class="disclosure-hierarchy-button hover:gl-no-underline active:!gl-no-underline"
      :class="{ 'gl-cursor-help': item.ancestorNotAvailable }"
    >
      <gl-icon v-if="shouldDisplayIcon(item.icon)" :name="item.icon" class="gl-mx-2 gl-shrink-0" />
      <span class="gl-z-200 gl-truncate">{{ item.title }}</span>
    </gl-link>
    <!--
      @slot Additional content to be displayed in an item.
      @binding {Object} item The item being rendered.
      @binding {String} itemId The rendered item's ID.
    -->
    <slot :item="item" :item-id="itemId"></slot>
  </li>
</template>

<script>
import iconSpriteInfo from '@gitlab/svgs/dist/icons.json';
import { GlIcon, GlLink } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { titleInLinkSafeHtmlConfig } from '~/lib/dompurify';
import { ISSUABLE_EPIC } from '../../constants';

export default {
  name: 'DisclosureHierarchyItem',
  components: {
    GlIcon,
    GlLink,
  },
  directives: {
    SafeHtml,
  },
  titleInLinkSafeHtmlConfig,
  props: {
    /**
     * Path item in the form:
     * ```
     * {
     *   titleHtml: String (rendered as HTML)
     *   message:   String (rendered as plain text)
     *   icon:      String, optional
     *   ancestorNotAvailable: Boolean, optional
     * }
     * ```
     * Exactly one of either titleHtml or message must be provided.
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
      <span
        v-if="item.titleHtml"
        v-safe-html:[$options.titleInLinkSafeHtmlConfig]="item.titleHtml"
        class="gl-z-200 gl-truncate"
      ></span>
      <span v-else class="gl-z-200 gl-truncate">{{ item.message }}</span>
    </gl-link>
    <!--
      @slot Additional content to be displayed in an item.
      @binding {Object} item The item being rendered.
      @binding {String} itemId The rendered item's ID.
    -->
    <slot :item="item" :item-id="itemId"></slot>
  </li>
</template>

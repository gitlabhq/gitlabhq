<script>
import { GlBadge, GlDisclosureDropdownGroup, GlDisclosureDropdownItem, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

const PLACEMENTS = ['help_menu', 'profile_menu'];

export default {
  name: 'WhatsNewForYouMenuItem',
  i18n: {
    label: __("What's new for you"),
  },
  components: {
    GlBadge,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    GlIcon,
  },
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
    placement: {
      type: String,
      required: true,
      validator: (value) => PLACEMENTS.includes(value),
    },
    icon: {
      type: String,
      required: false,
      default: null,
    },
  },
  emits: ['action'],
  data() {
    return {
      unreadCount: this.calculateInitialUnreadCount(),
      toggleDrawerFn: null,
    };
  },
  computed: {
    displayWhatsNew() {
      return Boolean(this.sidebarData.display_whats_new);
    },
    dataTestId() {
      return `whats-new-for-you-${this.placement.replace('_', '-')}-item`;
    },
    item() {
      return {
        text: this.$options.i18n.label,
        extraAttrs: {
          'data-track-action': 'click_whats_new_for_you_menu_item',
          'data-track-property': this.placement,
          'data-track-experiment': 'whats_new_placement',
        },
      };
    },
  },
  methods: {
    calculateInitialUnreadCount() {
      if (!this.sidebarData.display_whats_new) return 0;

      const total = this.sidebarData.whats_new_most_recent_release_items_count ?? 0;
      const read = this.sidebarData.whats_new_read_articles?.length ?? 0;
      return Math.max(total - read, 0);
    },
    async open() {
      this.$emit('action');

      if (this.toggleDrawerFn) {
        this.toggleDrawerFn();
        return;
      }

      const { default: launchDrawer } = await import(
        /* webpackChunkName: 'whatsNewApp' */ '~/whats_new'
      );
      this.toggleDrawerFn = launchDrawer;

      this.toggleDrawerFn(
        {
          versionDigest: this.sidebarData.whats_new_version_digest,
          initialReadArticles: this.sidebarData.whats_new_read_articles,
          markAsReadPath: this.sidebarData.whats_new_mark_as_read_path,
          mostRecentReleaseItemsCount: this.sidebarData.whats_new_most_recent_release_items_count,
          placement: this.placement,
        },
        (count) => {
          this.unreadCount = count;
        },
      );
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-group v-if="displayWhatsNew">
    <gl-disclosure-dropdown-item :item="item" :data-testid="dataTestId" @action="open">
      <template #list-item>
        <span class="gl-flex gl-w-full gl-items-center gl-gap-3">
          <gl-icon v-if="icon" :name="icon" variant="subtle" />
          <span>{{ $options.i18n.label }}</span>
          <gl-badge
            v-if="unreadCount"
            variant="info"
            class="gl-ml-auto"
            aria-hidden="true"
            data-testid="whats-new-info-badge"
            >{{ unreadCount }}</gl-badge
          >
        </span>
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown-group>
</template>

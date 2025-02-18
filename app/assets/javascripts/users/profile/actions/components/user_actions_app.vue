<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';

export default {
  components: {
    GlDisclosureDropdown,
    AbuseCategorySelector,
  },
  props: {
    userId: {
      type: String,
      required: true,
    },
    rssSubscriptionPath: {
      type: String,
      required: false,
      default: '',
    },
    reportedUserId: {
      type: Number,
      required: false,
      default: null,
    },
    reportedFromUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      defaultDropdownItems: [
        {
          action: this.onUserIdCopy,
          text: sprintf(this.$options.i18n.userId, { id: this.userId }),
          extraAttrs: {
            'data-clipboard-text': this.userId,
          },
        },
      ],
      open: false,
    };
  },
  computed: {
    dropdownItems() {
      const dropdownItems = this.defaultDropdownItems.slice();
      if (this.rssSubscriptionPath) {
        dropdownItems.push({
          href: this.rssSubscriptionPath,
          text: this.$options.i18n.rssSubscribe,
          extraAttrs: {
            'data-testid': 'user-profile-rss-subscription-link',
          },
        });
      }
      if (this.reportedUserId) {
        dropdownItems.push({
          action: () => this.toggleDrawer(true),
          text: this.$options.i18n.reportToAdmin,
        });
      }
      return dropdownItems;
    },
  },
  methods: {
    onUserIdCopy() {
      this.$toast.show(this.$options.i18n.userIdCopied);
    },
    toggleDrawer(open) {
      this.open = open;
    },
  },
  i18n: {
    userId: s__('UserProfile|Copy user ID: %{id}'),
    userIdCopied: s__('UserProfile|User ID copied to clipboard'),
    rssSubscribe: s__('UserProfile|Subscribe'),
    reportToAdmin: s__('ReportAbuse|Report abuse'),
  },
};
</script>

<template>
  <span>
    <gl-disclosure-dropdown
      data-testid="user-profile-actions"
      icon="ellipsis_v"
      category="tertiary"
      no-caret
      text-sr-only
      :toggle-text="__('More actions')"
      :items="dropdownItems"
    />
    <abuse-category-selector
      v-if="reportedUserId"
      :reported-user-id="reportedUserId"
      :reported-from-url="reportedFromUrl"
      :show-drawer="open"
      @close-drawer="toggleDrawer(false)"
    />
  </span>
</template>

<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';

export default {
  components: {
    GlDisclosureDropdown,
  },
  props: {
    userId: {
      type: String,
      required: true,
    },
    rssSubscriptionPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      // Only implement the copy function and RSS subscription in MR for now
      // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122971
      // The rest will be implemented in the upcoming MR.
      defaultDropdownItems: [
        {
          action: this.onUserIdCopy,
          text: sprintf(this.$options.i18n.userId, { id: this.userId }),
          extraAttrs: {
            'data-clipboard-text': this.userId,
          },
        },
      ],
    };
  },
  computed: {
    dropdownItems() {
      if (this.rssSubscriptionPath) {
        return [
          ...this.defaultDropdownItems,
          {
            href: this.rssSubscriptionPath,
            text: this.$options.i18n.rssSubscribe,
            extraAttrs: {
              'data-testid': 'user-profile-rss-subscription-link',
            },
          },
        ];
      }
      return this.defaultDropdownItems;
    },
  },
  methods: {
    onUserIdCopy() {
      this.$toast.show(this.$options.i18n.userIdCopied);
    },
  },
  i18n: {
    userId: s__('UserProfile|Copy user ID: %{id}'),
    userIdCopied: s__('UserProfile|User ID copied to clipboard'),
    rssSubscribe: s__('UserProfile|Subscribe'),
  },
};
</script>

<template>
  <gl-disclosure-dropdown icon="ellipsis_v" category="tertiary" no-caret :items="dropdownItems" />
</template>

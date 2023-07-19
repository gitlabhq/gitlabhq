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
  },
  data() {
    return {
      // Only implement the copy function in MR for now
      // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122971
      // The rest will be implemented in the upcoming MR.
      dropdownItems: [
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
  methods: {
    onUserIdCopy() {
      this.$toast.show(this.$options.i18n.userIdCopied);
    },
  },
  i18n: {
    userId: s__('UserProfile|Copy user ID: %{id}'),
    userIdCopied: s__('UserProfile|User ID copied to clipboard'),
  },
};
</script>

<template>
  <gl-disclosure-dropdown icon="ellipsis_v" category="tertiary" no-caret :items="dropdownItems" />
</template>

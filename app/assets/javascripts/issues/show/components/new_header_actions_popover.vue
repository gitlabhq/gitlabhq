<script>
import { GlPopover, GlButton } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { getCookie, parseBoolean, setCookie } from '~/lib/utils/common_utils';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { NEW_ACTIONS_POPOVER_KEY } from '~/issues/show/constants';
import { IssuableTypeText } from '~/issues/constants';

export default {
  name: 'NewHeaderActionsPopover',
  i18n: {
    popoverText: s__(
      'HeaderAction|Notifications and other %{issueType} actions have moved to this menu.',
    ),
    confirmButtonText: s__('HeaderAction|Okay!'),
  },
  components: {
    GlPopover,
    GlButton,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    issueType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      dismissKey: NEW_ACTIONS_POPOVER_KEY,
      popoverDismissed: parseBoolean(getCookie(`${NEW_ACTIONS_POPOVER_KEY}`)),
    };
  },
  computed: {
    popoverText() {
      return sprintf(this.$options.i18n.popoverText, {
        issueType: IssuableTypeText[this.issueType],
      });
    },
    showPopover() {
      return !this.popoverDismissed && this.isMrSidebarMoved;
    },
    isMrSidebarMoved() {
      return this.glFeatures.movedMrSidebar;
    },
  },
  methods: {
    dismissPopover() {
      this.popoverDismissed = true;
      setCookie(this.dismissKey, this.popoverDismissed);
    },
  },
};
</script>

<template>
  <div>
    <gl-popover
      v-if="showPopover"
      target="new-actions-header-dropdown"
      container="viewport"
      placement="left"
      :show="showPopover"
      triggers="manual"
      content="text"
      :css-classes="['gl-p-2 new-header-popover']"
    >
      <template #title>
        <div class="gl-font-base gl-font-weight-normal">
          {{ popoverText }}
        </div>
      </template>
      <gl-button
        data-testid="confirm-button"
        variant="confirm"
        type="submit"
        @click="dismissPopover"
        >{{ $options.i18n.confirmButtonText }}</gl-button
      >
    </gl-popover>
  </div>
</template>

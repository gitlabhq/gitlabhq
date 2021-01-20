<script>
import { s__, __, sprintf } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  i18n: {
    copyEmail: __('Copy email address'),
  },
  components: {
    ClipboardButton,
  },
  props: {
    copyText: {
      type: String,
      required: true,
    },
  },
  computed: {
    emailText() {
      return sprintf(s__('RightSidebar|Issue email: %{copyText}'), { copyText: this.copyText });
    },
  },
};
</script>

<template>
  <div
    data-qa-selector="copy-forward-email"
    class="copy-email-address gl-display-flex gl-align-items-center gl-justify-content-space-between"
  >
    <span
      class="gl-overflow-hidden gl-text-overflow-ellipsis gl-white-space-nowrap hide-collapsed gl-w-85p"
      >{{ emailText }}</span
    >
    <clipboard-button
      class="copy-email-button gl-bg-none!"
      category="tertiary"
      :title="$options.i18n.copyEmail"
      :text="copyText"
      tooltip-placement="left"
    />
  </div>
</template>

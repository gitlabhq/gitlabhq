<script>
import { GlSprintf, GlButton, GlAlert, GlCard } from '@gitlab/ui';
import { Mousetrap, MOUSETRAP_COPY_KEYBOARD_SHORTCUT } from '~/lib/mousetrap';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import {
  COPY_BUTTON_ACTION,
  DOWNLOAD_BUTTON_ACTION,
  PRINT_BUTTON_ACTION,
  TRACKING_LABEL_PREFIX,
  RECOVERY_CODE_DOWNLOAD_FILENAME,
} from '../constants';

export const i18n = {
  pageTitle: __('Two-factor Authentication Recovery codes'),
  alertTitle: __('Please copy, download, or print your recovery codes before proceeding.'),
  pageDescription: __(
    'Should you ever lose your phone or access to your one time password secret, each of these recovery codes can be used one time each to regain access to your account. Please save them in a safe place, or you %{boldStart}will%{boldEnd} lose access to your account.',
  ),
  copyButton: __('Copy codes'),
  downloadButton: __('Download codes'),
  printButton: __('Print codes'),
  proceedButton: __('Proceed'),
};

export default {
  name: 'RecoveryCodes',
  copyButtonAction: COPY_BUTTON_ACTION,
  downloadButtonAction: DOWNLOAD_BUTTON_ACTION,
  printButtonAction: PRINT_BUTTON_ACTION,
  trackingLabelPrefix: TRACKING_LABEL_PREFIX,
  recoveryCodeDownloadFilename: RECOVERY_CODE_DOWNLOAD_FILENAME,
  i18n,
  mousetrap: null,
  components: { GlSprintf, GlButton, GlAlert, ClipboardButton, GlCard, PageHeading },
  mixins: [Tracking.mixin()],
  props: {
    codes: {
      type: Array,
      required: true,
    },
    profileAccountPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      proceedButtonDisabled: true,
    };
  },
  computed: {
    codesAsString() {
      return this.codes.join('\n');
    },
    codeDownloadUrl() {
      return `data:text/plain;charset=utf-8,${encodeURIComponent(this.codesAsString)}`;
    },
  },
  created() {
    this.$options.mousetrap = new Mousetrap();

    this.$options.mousetrap.bind(MOUSETRAP_COPY_KEYBOARD_SHORTCUT, this.handleKeyboardCopy);
  },
  beforeDestroy() {
    if (!this.$options.mousetrap) {
      return;
    }

    this.$options.mousetrap.unbind(MOUSETRAP_COPY_KEYBOARD_SHORTCUT);
  },
  methods: {
    handleButtonClick(action) {
      this.proceedButtonDisabled = false;

      if (action === this.$options.printButtonAction) {
        window.print();
      }

      this.track('click_button', { label: `${this.$options.trackingLabelPrefix}${action}_button` });
    },
    handleKeyboardCopy() {
      if (!window.getSelection) {
        return;
      }

      const copiedText = window.getSelection().toString();

      if (copiedText.includes(this.codesAsString)) {
        this.proceedButtonDisabled = false;
        this.track('copy_keyboard_shortcut', {
          label: `${this.$options.trackingLabelPrefix}manual_copy`,
        });
      }
    },
  },
};
</script>

<template>
  <div>
    <page-heading :heading="$options.i18n.pageTitle">
      <template #description>
        <gl-sprintf :message="$options.i18n.pageDescription">
          <template #bold="{ content }"
            ><strong>{{ content }}</strong></template
          >
        </gl-sprintf>
      </template>
    </page-heading>

    <gl-alert variant="info" :dismissible="false">
      {{ $options.i18n.alertTitle }}
    </gl-alert>

    <gl-card class="codes-to-print gl-my-5" data-testid="recovery-codes">
      <ul class="gl-m-0 gl-pl-5">
        <li v-for="(code, index) in codes" :key="index">
          <span class="gl-font-monospace" data-testid="code-content">{{ code }}</span>
        </li>
      </ul>
    </gl-card>
    <div class="-gl-mx-2 -gl-my-2 gl-flex gl-flex-wrap">
      <div class="gl-p-2">
        <clipboard-button
          :title="$options.i18n.copyButton"
          :text="codesAsString"
          data-testid="copy-button"
          @click="handleButtonClick($options.copyButtonAction)"
        >
          {{ $options.i18n.copyButton }}
        </clipboard-button>
      </div>
      <div class="gl-p-2">
        <gl-button
          is-unsafe-link
          :href="codeDownloadUrl"
          :title="$options.i18n.downloadButton"
          icon="download"
          :download="$options.recoveryCodeDownloadFilename"
          @click="handleButtonClick($options.downloadButtonAction)"
        >
          {{ $options.i18n.downloadButton }}
        </gl-button>
      </div>
      <div class="gl-p-2">
        <gl-button
          :title="$options.i18n.printButton"
          @click="handleButtonClick($options.printButtonAction)"
        >
          {{ $options.i18n.printButton }}
        </gl-button>
      </div>
      <div class="gl-p-2">
        <gl-button
          :href="profileAccountPath"
          :disabled="proceedButtonDisabled"
          :title="$options.i18n.proceedButton"
          variant="confirm"
          data-testid="proceed-button"
          data-track-action="click_button"
          :data-track-label="`${$options.trackingLabelPrefix}proceed_button`"
          >{{ $options.i18n.proceedButton }}</gl-button
        >
      </div>
    </div>
  </div>
</template>

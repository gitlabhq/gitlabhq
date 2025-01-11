<script>
import { GlIcon, GlLink, GlModal, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

export const WARNING_PARAGRAPH_1 = s__(
  'PreferencesIntegrations|Third-party extensions are now available in the Web IDE and Workspaces. While each extension runs in a secure browser sandbox, %{boldStart}third-party extensions%{boldEnd} may have access to the contents of the files opened in the Web IDE or Workspaces, %{boldStart}including any personal data in those files%{boldEnd}, and may communicate with external servers.',
);

export const WARNING_PARAGRAPH_2 = s__(
  'PreferencesIntegrations|GitLab does not assume any responsibility for the functionality of these third-party extensions. Each %{boldStart}third-party%{boldEnd} extension has %{boldStart}their own independent%{boldEnd} terms and conditions listed in the marketplace. By installing an extension, you are agreeing to the terms & conditions and Privacy Policy that govern each individual extension as listed in the marketplace.',
);

export const WARNING_PARAGRAPH_3 = s__(
  'PreferencesIntegrations|By using the Extension Marketplace, you will send data, such as IP address and other device information, to %{url} in accordance with their independent terms and privacy policy.',
);

export default {
  components: {
    GlIcon,
    GlLink,
    GlModal,
    GlSprintf,
  },
  inject: {
    extensionsMarketplaceUrl: {
      default: '',
    },
  },
  props: {
    value: {
      type: Boolean,
      required: true,
    },
    helpUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      // If we have already enabled, let's consider warning not necessary
      needsWarning: !this.value,
      showWarning: false,
    };
  },
  computed: {
    actionSecondary() {
      if (!this.helpUrl) {
        return undefined;
      }

      return {
        text: s__('PreferencesIntegrations|Learn more'),
        attributes: {
          href: this.helpUrl,
          variant: 'default',
        },
      };
    },
  },
  watch: {
    value(val) {
      // Have we tried to accept but we need to show the warning?
      if (val && this.needsWarning) {
        this.showWarning = true;
      }
    },
    async showWarning(val) {
      // Wait a bit so that `needsWarning` is properly updated if accepting.
      await this.$nextTick();

      // If we are showing the warning, the value should be false. Don't treat the user as accepting yet.
      if (val) {
        this.$emit('input', false);
      } else if (!this.needsWarning) {
        this.$emit('input', true);
      }
    },
  },
  methods: {
    onPrimary() {
      this.needsWarning = false;
    },
  },
  actionPrimary: {
    text: s__('PreferencesIntegrations|I understand'),
    attributes: {
      variant: 'confirm',
      category: 'primary',
      'data-testid': 'confirm-marketplace-acknowledgement',
    },
  },
  TITLE: s__('PreferencesIntegrations|Third-Party Extensions Acknowledgement'),
  WARNING_PARAGRAPH_1,
  WARNING_PARAGRAPH_2,
  WARNING_PARAGRAPH_3,
};
</script>

<template>
  <gl-modal
    v-model="showWarning"
    modal-id="extensions-marketplace-warning-modal"
    :title="$options.TITLE"
    :action-primary="$options.actionPrimary"
    :action-secondary="actionSecondary"
    @primary="onPrimary"
  >
    <p>
      <gl-sprintf :message="$options.WARNING_PARAGRAPH_1">
        <template #bold="{ content }">
          <span class="gl-font-bold">{{ content }}</span>
        </template>
      </gl-sprintf>
    </p>
    <p>
      <gl-sprintf :message="$options.WARNING_PARAGRAPH_2">
        <template #bold="{ content }">
          <span class="gl-font-bold">{{ content }}</span>
        </template>
      </gl-sprintf>
    </p>
    <p>
      <gl-sprintf v-if="extensionsMarketplaceUrl" :message="$options.WARNING_PARAGRAPH_3">
        <template #url>
          <gl-link :href="extensionsMarketplaceUrl" target="_blank"
            >{{ extensionsMarketplaceUrl }}
            <gl-icon name="external-link" class="gl-align-middle" :size="12" />
          </gl-link>
        </template>
      </gl-sprintf>
    </p>
  </gl-modal>
</template>

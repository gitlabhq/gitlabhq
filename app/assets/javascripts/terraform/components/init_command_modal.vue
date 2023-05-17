<script>
import { GlModal, GlSprintf, GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

export default {
  i18n: {
    title: s__('Terraform|Terraform init command'),
    explanatoryText: s__(
      `Terraform|To get access to this terraform state from your local computer, run the following command at the command line. The first line requires a personal access token with API read and write access. %{linkStart}How do I create a personal access token?%{linkEnd}.`,
    ),
    closeText: __('Close'),
    copyToClipboardText: __('Copy'),
  },
  components: {
    GlModal,
    GlSprintf,
    GlLink,
    ModalCopyButton,
  },
  inject: ['accessTokensPath', 'terraformApiUrl', 'username'],
  props: {
    modalId: {
      type: String,
      required: true,
    },
    stateName: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    closeModalProps() {
      return {
        text: this.$options.i18n.closeText,
        attributes: {},
      };
    },
  },
  methods: {
    getModalInfoCopyStr() {
      const stateNameEncoded = this.stateName
        ? encodeURIComponent(this.stateName)
        : '<YOUR-STATE-NAME>';

      return `export GITLAB_ACCESS_TOKEN=<YOUR-ACCESS-TOKEN>
terraform init \\
    -backend-config="address=${this.terraformApiUrl}/${stateNameEncoded}" \\
    -backend-config="lock_address=${this.terraformApiUrl}/${stateNameEncoded}/lock" \\
    -backend-config="unlock_address=${this.terraformApiUrl}/${stateNameEncoded}/lock" \\
    -backend-config="username=${this.username}" \\
    -backend-config="password=$GITLAB_ACCESS_TOKEN" \\
    -backend-config="lock_method=POST" \\
    -backend-config="unlock_method=DELETE" \\
    -backend-config="retry_wait_min=5"
    `;
    },
  },
};
</script>

<template>
  <gl-modal
    ref="initCommandModal"
    :modal-id="modalId"
    :title="$options.i18n.title"
    :action-cancel="closeModalProps"
  >
    <p data-testid="init-command-explanatory-text">
      <gl-sprintf :message="$options.i18n.explanatoryText">
        <template #link="{ content }">
          <gl-link :href="accessTokensPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>

    <div class="gl-display-flex">
      <pre class="gl-bg-gray gl-white-space-pre-wrap" data-testid="terraform-init-command">{{
        getModalInfoCopyStr()
      }}</pre>
      <modal-copy-button
        :title="$options.i18n.copyToClipboardText"
        :text="getModalInfoCopyStr()"
        :modal-id="$options.modalId"
        data-testid="init-command-copy-clipboard"
        css-classes="gl-align-self-start gl-ml-2"
      />
    </div>
  </gl-modal>
</template>

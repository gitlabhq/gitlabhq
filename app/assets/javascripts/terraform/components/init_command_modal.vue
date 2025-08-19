<script>
import { GlModal, GlSprintf, GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

export default {
  i18n: {
    title: s__('Terraform|Terraform init'),
    explanatoryText: s__(
      `Terraform|To access this Terraform state from your local computer, use either GitLab CLI (glab) or the REST API.`,
    ),
    explanatoryGlabText: s__(
      `Terraform|Recommended. Run the following command with glab. You must use glab 1.66 or later:`,
    ),
    explanatoryPlainText: s__(
      `Terraform|Alternatively, use the Terraform or OpenTofu CLI directly. You must use a personal access token with the scope set to api. %{linkStart}How do I create a personal access token?%{linkEnd}.`,
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
  inject: ['accessTokensPath', 'terraformApiUrl', 'username', 'projectPath'],
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
    getModalInfoGlabCopyStr() {
      const stateName = this.stateName ? this.stateName : 'default';
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `glab opentofu init -R '${this.projectPath}' '${stateName}'`;
    },
    getModalInfoPlainCopyStr() {
      const stateNameEncoded = this.stateName ? encodeURIComponent(this.stateName) : 'default';

      return `export GITLAB_ACCESS_TOKEN=<YOUR-ACCESS-TOKEN>
export TF_STATE_NAME=${stateNameEncoded}
terraform init \\
    -backend-config="address=${this.terraformApiUrl}/$TF_STATE_NAME" \\
    -backend-config="lock_address=${this.terraformApiUrl}/$TF_STATE_NAME/lock" \\
    -backend-config="unlock_address=${this.terraformApiUrl}/$TF_STATE_NAME/lock" \\
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
      {{ $options.i18n.explanatoryText }}
    </p>

    <p data-testid="init-command-explanatory-glab-text">
      {{ $options.i18n.explanatoryGlabText }}
    </p>

    <div class="gl-mb-3 gl-flex">
      <pre
        class="code-block rounded gl-border gl-mb-0 gl-w-full gl-py-2"
        data-testid="glab-command"
        >{{ getModalInfoGlabCopyStr() }}</pre
      >
      <modal-copy-button
        :title="$options.i18n.copyToClipboardText"
        :text="getModalInfoGlabCopyStr()"
        :modal-id="$options.modalId"
        css-classes="gl-self-start gl-ml-2"
        data-testid="glab-command-copy-button"
      />
    </div>

    <p data-testid="init-command-explanatory-plain-text">
      <gl-sprintf :message="$options.i18n.explanatoryPlainText">
        <template #link="{ content }">
          <gl-link :href="accessTokensPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>

    <div class="gl-flex">
      <pre class="gl-bg-gray gl-whitespace-pre-wrap" data-testid="terraform-init-command">{{
        getModalInfoPlainCopyStr()
      }}</pre>
      <modal-copy-button
        :title="$options.i18n.copyToClipboardText"
        :text="getModalInfoPlainCopyStr()"
        :modal-id="$options.modalId"
        css-classes="gl-self-start gl-ml-2"
        data-testid="terraform-init-command-copy-button"
      />
    </div>
  </gl-modal>
</template>

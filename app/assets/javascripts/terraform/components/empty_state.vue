<script>
import { GlEmptyState, GlButton, GlModalDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import InitCommandModal from './init_command_modal.vue';

export default {
  COMMAND_MODAL_ID: 'init-command-modal',
  i18n: {
    title: s__("Terraform|Your project doesn't have any Terraform state files"),
    buttonDoc: s__('Terraform|Explore documentation'),
    buttonCopy: s__('Terraform|Copy Terraform init command'),
  },
  docsUrl: helpPagePath('user/infrastructure/iac/terraform_state'),
  components: {
    GlEmptyState,
    GlButton,
    InitCommandModal,
  },

  directives: {
    GlModalDirective,
  },

  props: {
    image: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-empty-state :svg-path="image" :svg-height="null" :title="$options.i18n.title">
    <template #actions>
      <gl-button variant="confirm" :href="$options.docsUrl" class="gl-mx-2 gl-mb-3">
        {{ $options.i18n.buttonDoc }}</gl-button
      >
      <gl-button
        v-gl-modal-directive="$options.COMMAND_MODAL_ID"
        class="gl-mx-2 gl-mb-3"
        data-testid="terraform-state-copy-init-command"
        icon="copy-to-clipboard"
        >{{ $options.i18n.buttonCopy }}</gl-button
      >

      <init-command-modal :modal-id="$options.COMMAND_MODAL_ID" />
    </template>
  </gl-empty-state>
</template>

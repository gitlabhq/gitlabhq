<script>
import { GlAlert, GlFormInputGroup, GlLink, GlSprintf, GlIcon } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import CodeBlock from '~/vue_shared/components/code_block.vue';
import { generateAgentRegistrationCommand } from '../clusters_util';
import { I18N_AGENT_TOKEN, HELM_VERSION_POLICY_URL } from '../constants';

export default {
  i18n: I18N_AGENT_TOKEN,
  advancedInstallPath: helpPagePath('user/clusters/agent/install/_index', {
    anchor: 'advanced-installation-method',
  }),
  HELM_VERSION_POLICY_URL,
  components: {
    GlAlert,
    CodeBlock,
    GlFormInputGroup,
    GlLink,
    GlSprintf,
    GlIcon,
    ModalCopyButton,
  },
  inject: ['kasAddress', 'kasInstallVersion'],
  props: {
    agentName: {
      required: true,
      type: String,
    },
    agentToken: {
      required: true,
      type: String,
    },
    modalId: {
      required: true,
      type: String,
    },
  },
  computed: {
    agentRegistrationCommand() {
      return generateAgentRegistrationCommand({
        name: this.agentName,
        token: this.agentToken,
        version: this.kasInstallVersion,
        address: this.kasAddress,
      });
    },
  },
};
</script>

<template>
  <div>
    <p class="gl-mb-3">{{ $options.i18n.tokenLabel }}</p>

    <p>
      <gl-form-input-group readonly :value="agentToken" :select-on-click="true">
        <template #append>
          <modal-copy-button
            :text="agentToken"
            :title="$options.i18n.copyToken"
            :modal-id="modalId"
          />
        </template>
      </gl-form-input-group>
    </p>

    <p>
      {{ $options.i18n.tokenSubtitle }}
    </p>

    <gl-alert :dismissible="false" variant="warning" class="gl-mb-5">
      {{ $options.i18n.tokenSingleUseWarningTitle }}
    </gl-alert>

    <p>
      <strong>{{ $options.i18n.basicInstallTitle }}</strong>
    </p>

    <p>
      {{ $options.i18n.basicInstallBody }}
      <gl-sprintf :message="$options.i18n.helmVersionText">
        <template #link="{ content }"
          ><gl-link :href="$options.HELM_VERSION_POLICY_URL" target="_blank"
            >{{ content }} <gl-icon name="external-link" :size="12" /></gl-link></template
      ></gl-sprintf>
    </p>

    <p class="gl-flex gl-items-start">
      <code-block class="gl-w-full" :code="agentRegistrationCommand" />
      <modal-copy-button
        data-testid="agent-registration-command"
        :title="$options.i18n.copyCommand"
        :text="agentRegistrationCommand"
        :modal-id="modalId"
      />
    </p>

    <p>
      <strong>{{ $options.i18n.advancedInstallTitle }}</strong>
    </p>

    <p>
      <gl-sprintf :message="$options.i18n.advancedInstallBody">
        <template #link="{ content }">
          <gl-link :href="$options.advancedInstallPath" target="_blank"> {{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
  </div>
</template>

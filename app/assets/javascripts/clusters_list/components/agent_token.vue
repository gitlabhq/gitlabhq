<script>
import { GlAlert, GlFormInputGroup, GlLink, GlSprintf, GlIcon } from '@gitlab/ui';
import SimpleCopyButton from '~/vue_shared/components/simple_copy_button.vue';
import CodeBlock from '~/vue_shared/components/code_block.vue';
import { generateAgentRegistrationCommand } from '../clusters_util';
import { I18N_AGENT_TOKEN, HELM_VERSION_POLICY_URL } from '../constants';

export default {
  i18n: I18N_AGENT_TOKEN,
  HELM_VERSION_POLICY_URL,
  components: {
    GlAlert,
    CodeBlock,
    GlFormInputGroup,
    GlLink,
    GlSprintf,
    GlIcon,
    SimpleCopyButton,
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
          <simple-copy-button :text="agentToken" :title="$options.i18n.copyToken" />
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
      <simple-copy-button
        data-testid="agent-registration-command"
        :title="$options.i18n.copyCommand"
        :text="agentRegistrationCommand"
      />
    </p>
  </div>
</template>

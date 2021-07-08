<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { mapState } from 'vuex';
import { s__ } from '~/locale';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';

export default {
  name: 'ConanInstallation',
  components: {
    CodeInstruction,
    GlLink,
    GlSprintf,
  },
  computed: {
    ...mapState(['packageEntity', 'terraformHelpPath', 'gitlabHost', 'projectPath']),
    provisionInstructions() {
      return `module "my_module_name" {
  source = "${this.gitlabHost}/${this.projectPath}/${this.packageEntity.name}"
  version = "${this.packageEntity.version}"
}`;
    },
    registrySetup() {
      return `credentials "${this.gitlabHost}" {
  token = "<TOKEN>"
}`;
    },
  },
  i18n: {
    helpText: s__(
      'InfrastructureRegistry|For more information on the Terraform registry, %{linkStart}see our documentation%{linkEnd}.',
    ),
  },
};
</script>

<template>
  <div>
    <h3 class="gl-font-lg">{{ __('Provision instructions') }}</h3>

    <code-instruction
      :label="
        s__(
          'InfrastructureRegistry|Copy and paste into your Terraform configuration, insert the variables, and run Terraform init:',
        )
      "
      :instruction="provisionInstructions"
      :copy-text="s__('InfrastructureRegistry|Copy Terraform Command')"
      multiline
    />

    <h3 class="gl-font-lg">{{ __('Registry setup') }}</h3>

    <code-instruction
      :label="s__('InfrastructureRegistry|To authorize access to the Terraform registry:')"
      :instruction="registrySetup"
      :copy-text="s__('InfrastructureRegistry|Copy Terraform Setup Command')"
      multiline
    />
    <gl-sprintf :message="$options.i18n.helpText">
      <template #link="{ content }">
        <gl-link :href="terraformHelpPath">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>

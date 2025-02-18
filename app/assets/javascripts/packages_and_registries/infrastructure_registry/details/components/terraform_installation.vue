<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';

export default {
  components: {
    CodeInstruction,
    GlLink,
    GlSprintf,
  },
  inject: ['gitlabHost', 'projectPath'],
  props: {
    packageName: {
      type: String,
      required: true,
    },
    packageVersion: {
      type: String,
      required: true,
    },
  },
  computed: {
    provisionInstructions() {
      return `module "my_module_name" {
  source = "${this.gitlabHost}/${this.projectPath}/${this.packageName}"
  version = "${this.packageVersion}"
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
  terraformHelpPath: helpPagePath('user/packages/terraform_module_registry/_index', {
    anchor: 'reference-a-terraform-module',
  }),
};
</script>

<template>
  <div>
    <h3 class="gl-text-lg">{{ __('Provision instructions') }}</h3>

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

    <h3 class="gl-text-lg">{{ __('Registry setup') }}</h3>

    <code-instruction
      :label="s__('InfrastructureRegistry|To authorize access to the Terraform registry:')"
      :instruction="registrySetup"
      :copy-text="s__('InfrastructureRegistry|Copy Terraform Setup Command')"
      multiline
    />
    <gl-sprintf :message="$options.i18n.helpText">
      <template #link="{ content }">
        <gl-link :href="$options.terraformHelpPath">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>

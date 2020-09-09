<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { mapGetters, mapState } from 'vuex';
import { s__ } from '~/locale';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';
import { TrackingActions, TrackingLabels } from '../constants';

export default {
  name: 'MavenInstallation',
  components: {
    CodeInstruction,
    GlLink,
    GlSprintf,
  },
  computed: {
    ...mapState(['mavenHelpPath']),
    ...mapGetters(['mavenInstallationXml', 'mavenInstallationCommand', 'mavenSetupXml']),
  },
  i18n: {
    xmlText: s__(
      `PackageRegistry|Copy and paste this inside your %{codeStart}pom.xml%{codeEnd} %{codeStart}dependencies%{codeEnd} block.`,
    ),
    setupText: s__(
      `PackageRegistry|If you haven't already done so, you will need to add the below to your %{codeStart}pom.xml%{codeEnd} file.`,
    ),
    helpText: s__(
      'PackageRegistry|For more information on the Maven registry, %{linkStart}see the documentation%{linkEnd}.',
    ),
  },
  trackingActions: { ...TrackingActions },
  TrackingLabels,
};
</script>

<template>
  <div>
    <h3 class="gl-font-lg">{{ __('Installation') }}</h3>

    <p>
      <gl-sprintf :message="$options.i18n.xmlText">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>

    <code-instruction
      :label="s__('PackageRegistry|Maven XML')"
      :instruction="mavenInstallationXml"
      :copy-text="s__('PackageRegistry|Copy Maven XML')"
      multiline
      :tracking-action="$options.trackingActions.COPY_MAVEN_XML"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
    />

    <code-instruction
      :label="s__('PackageRegistry|Maven Command')"
      :instruction="mavenInstallationCommand"
      :copy-text="s__('PackageRegistry|Copy Maven command')"
      :tracking-action="$options.trackingActions.COPY_MAVEN_COMMAND"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
    />

    <h3 class="gl-font-lg">{{ __('Registry setup') }}</h3>
    <p>
      <gl-sprintf :message="$options.i18n.setupText">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>
    <code-instruction
      :instruction="mavenSetupXml"
      :copy-text="s__('PackageRegistry|Copy Maven registry XML')"
      multiline
      :tracking-action="$options.trackingActions.COPY_MAVEN_SETUP"
      :tracking-label="$options.TrackingLabels.CODE_INSTRUCTION"
    />
    <gl-sprintf :message="$options.i18n.helpText">
      <template #link="{ content }">
        <gl-link :href="mavenHelpPath" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>

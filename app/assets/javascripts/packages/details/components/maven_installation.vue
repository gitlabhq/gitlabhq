<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import { TrackingActions } from '../constants';
import { mapGetters, mapState } from 'vuex';

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
};
</script>

<template>
  <div>
    <h3 class="gl-font-lg">{{ __('Installation') }}</h3>

    <h4 class="gl-font-base">
      {{ s__('PackageRegistry|Maven XML') }}
    </h4>
    <p>
      <gl-sprintf :message="$options.i18n.xmlText">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>
    <code-instruction
      :instruction="mavenInstallationXml"
      :copy-text="s__('PackageRegistry|Copy Maven XML')"
      multiline
      :tracking-action="$options.trackingActions.COPY_MAVEN_XML"
    />

    <h4 class="gl-font-base">
      {{ s__('PackageRegistry|Maven Command') }}
    </h4>
    <code-instruction
      :instruction="mavenInstallationCommand"
      :copy-text="s__('PackageRegistry|Copy Maven command')"
      :tracking-action="$options.trackingActions.COPY_MAVEN_COMMAND"
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
    />
    <gl-sprintf :message="$options.i18n.helpText">
      <template #link="{ content }">
        <gl-link :href="mavenHelpPath" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>

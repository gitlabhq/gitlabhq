<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import { TrackingActions, TrackingLabels } from '../constants';
import { mapGetters, mapState } from 'vuex';
import InstallationTabs from './installation_tabs.vue';

export default {
  name: 'MavenInstallation',
  components: {
    CodeInstruction,
    GlLink,
    GlSprintf,
    InstallationTabs,
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
  trackingLabel: TrackingLabels.MAVEN_INSTALLATION,
};
</script>

<template>
  <installation-tabs :tracking-label="$options.trackingLabel">
    <template #installation>
      <p class="gl-mt-3 font-weight-bold">{{ s__('PackageRegistry|Maven XML') }}</p>
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
        class="js-maven-xml"
        multiline
        :tracking-action="$options.trackingActions.COPY_MAVEN_XML"
      />

      <p class="gl-mt-3 font-weight-bold">
        {{ s__('PackageRegistry|Maven Command') }}
      </p>
      <code-instruction
        :instruction="mavenInstallationCommand"
        :copy-text="s__('PackageRegistry|Copy Maven command')"
        class="js-maven-command"
        :tracking-action="$options.trackingActions.COPY_MAVEN_COMMAND"
      />
    </template>

    <template #setup>
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
        class="js-maven-setup-xml"
        multiline
        :tracking-action="$options.trackingActions.COPY_MAVEN_SETUP"
      />
      <gl-sprintf :message="$options.i18n.helpText">
        <template #link="{ content }">
          <gl-link :href="mavenHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </installation-tabs>
</template>

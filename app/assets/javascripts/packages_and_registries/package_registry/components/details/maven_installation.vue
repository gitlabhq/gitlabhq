<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import {
  TRACKING_ACTION_COPY_MAVEN_XML,
  TRACKING_ACTION_COPY_MAVEN_COMMAND,
  TRACKING_ACTION_COPY_MAVEN_SETUP,
  TRACKING_ACTION_COPY_GRADLE_INSTALL_COMMAND,
  TRACKING_ACTION_COPY_GRADLE_ADD_TO_SOURCE_COMMAND,
  TRACKING_ACTION_COPY_KOTLIN_INSTALL_COMMAND,
  TRACKING_ACTION_COPY_KOTLIN_ADD_TO_SOURCE_COMMAND,
  TRACKING_LABEL_CODE_INSTRUCTION,
  TRACKING_LABEL_MAVEN_INSTALLATION,
  MAVEN_HELP_PATH,
  MAVEN_INSTALLATION_COMMAND,
} from '~/packages_and_registries/package_registry/constants';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';

export default {
  name: 'MavenInstallation',
  components: {
    InstallationTitle,
    CodeInstruction,
    GlLink,
    GlSprintf,
  },
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      instructionType: 'maven',
    };
  },
  computed: {
    mavenUrl() {
      return this.packageEntity.mavenUrl;
    },
    appGroup() {
      return this.packageEntity.metadata.appGroup;
    },
    appName() {
      return this.packageEntity.metadata.appName;
    },
    appVersion() {
      return this.packageEntity.metadata.appVersion;
    },
    mavenInstallationXml() {
      return `<dependency>
  <groupId>${this.appGroup}</groupId>
  <artifactId>${this.appName}</artifactId>
  <version>${this.appVersion}</version>
</dependency>`;
    },
    mavenSetupXml() {
      return `<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>${this.mavenUrl}</url>
  </repository>
</repositories>

<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>${this.mavenUrl}</url>
  </repository>

  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>${this.mavenUrl}</url>
  </snapshotRepository>
</distributionManagement>`;
    },

    gradleGroovyInstalCommand() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `implementation '${this.appGroup}:${this.appName}:${this.appVersion}'`;
    },

    gradleGroovyAddSourceCommand() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `maven {
  url '${this.mavenUrl}'
}`;
    },

    gradleKotlinInstalCommand() {
      return `implementation("${this.appGroup}:${this.appName}:${this.appVersion}")`;
    },

    gradleKotlinAddSourceCommand() {
      return `maven("${this.mavenUrl}")`;
    },
    showMaven() {
      return this.instructionType === 'maven';
    },
    showGroovy() {
      return this.instructionType === 'groovy';
    },
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
  tracking: {
    TRACKING_ACTION_COPY_MAVEN_XML,
    TRACKING_ACTION_COPY_MAVEN_COMMAND,
    TRACKING_ACTION_COPY_MAVEN_SETUP,
    TRACKING_ACTION_COPY_GRADLE_INSTALL_COMMAND,
    TRACKING_ACTION_COPY_GRADLE_ADD_TO_SOURCE_COMMAND,
    TRACKING_ACTION_COPY_KOTLIN_INSTALL_COMMAND,
    TRACKING_ACTION_COPY_KOTLIN_ADD_TO_SOURCE_COMMAND,
    TRACKING_LABEL_CODE_INSTRUCTION,
    TRACKING_LABEL_MAVEN_INSTALLATION,
  },
  links: { MAVEN_HELP_PATH },
  installOptions: [
    { value: 'maven', label: s__('PackageRegistry|Maven XML') },
    { value: 'groovy', label: s__('PackageRegistry|Gradle Groovy DSL') },
    { value: 'kotlin', label: s__('PackageRegistry|Gradle Kotlin DSL') },
  ],
  MAVEN_INSTALLATION_COMMAND,
};
</script>

<template>
  <div>
    <installation-title
      package-type="maven"
      :options="$options.installOptions"
      @change="instructionType = $event"
    />

    <template v-if="showMaven">
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
        :tracking-action="$options.tracking.TRACKING_ACTION_COPY_MAVEN_XML"
        :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
        multiline
      />

      <code-instruction
        class="gl-mt-5 gl-w-20"
        :label="s__('PackageRegistry|Maven Command')"
        :instruction="$options.MAVEN_INSTALLATION_COMMAND"
        :copy-text="s__('PackageRegistry|Copy Maven command')"
        :tracking-action="$options.tracking.TRACKING_ACTION_COPY_MAVEN_COMMAND"
        :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
      />

      <h3 class="gl-text-lg">{{ s__('PackageRegistry|Registry setup') }}</h3>
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
        :tracking-action="$options.tracking.TRACKING_ACTION_COPY_MAVEN_SETUP"
        :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
        multiline
      />
      <gl-sprintf :message="$options.i18n.helpText">
        <template #link="{ content }">
          <gl-link :href="$options.links.MAVEN_HELP_PATH" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
    <template v-else-if="showGroovy">
      <code-instruction
        class="gl-mb-5"
        :label="s__('PackageRegistry|Gradle Groovy DSL install command')"
        :instruction="gradleGroovyInstalCommand"
        :copy-text="s__('PackageRegistry|Copy Gradle Groovy DSL install command')"
        :tracking-action="$options.tracking.TRACKING_ACTION_COPY_GRADLE_INSTALL_COMMAND"
        :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
      />
      <code-instruction
        :label="s__('PackageRegistry|Add Gradle Groovy DSL repository command')"
        :instruction="gradleGroovyAddSourceCommand"
        :copy-text="s__('PackageRegistry|Copy add Gradle Groovy DSL repository command')"
        :tracking-action="$options.tracking.TRACKING_ACTION_COPY_GRADLE_ADD_TO_SOURCE_COMMAND"
        :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
        multiline
      />
    </template>
    <template v-else>
      <code-instruction
        class="gl-mb-5"
        :label="s__('PackageRegistry|Gradle Kotlin DSL install command')"
        :instruction="gradleKotlinInstalCommand"
        :copy-text="s__('PackageRegistry|Copy Gradle Kotlin DSL install command')"
        :tracking-action="$options.tracking.TRACKING_ACTION_COPY_KOTLIN_INSTALL_COMMAND"
        :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
      />
      <code-instruction
        :label="s__('PackageRegistry|Add Gradle Kotlin DSL repository command')"
        :instruction="gradleKotlinAddSourceCommand"
        :copy-text="s__('PackageRegistry|Copy add Gradle Kotlin DSL repository command')"
        :tracking-action="$options.tracking.TRACKING_ACTION_COPY_KOTLIN_ADD_TO_SOURCE_COMMAND"
        :tracking-label="$options.tracking.TRACKING_LABEL_CODE_INSTRUCTION"
        multiline
      />
    </template>
  </div>
</template>

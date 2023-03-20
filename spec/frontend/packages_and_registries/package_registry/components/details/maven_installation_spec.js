import { GlLink, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import {
  packageData,
  mavenMetadata,
} from 'jest/packages_and_registries/package_registry/mock_data';
import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import MavenInstallation from '~/packages_and_registries/package_registry/components/details/maven_installation.vue';
import {
  TRACKING_ACTION_COPY_MAVEN_XML,
  TRACKING_ACTION_COPY_MAVEN_COMMAND,
  TRACKING_ACTION_COPY_MAVEN_SETUP,
  TRACKING_ACTION_COPY_GRADLE_INSTALL_COMMAND,
  TRACKING_ACTION_COPY_GRADLE_ADD_TO_SOURCE_COMMAND,
  TRACKING_ACTION_COPY_KOTLIN_INSTALL_COMMAND,
  TRACKING_ACTION_COPY_KOTLIN_ADD_TO_SOURCE_COMMAND,
  PACKAGE_TYPE_MAVEN,
  MAVEN_HELP_PATH,
} from '~/packages_and_registries/package_registry/constants';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';

describe('MavenInstallation', () => {
  let wrapper;

  const packageEntity = {
    ...packageData(),
    packageType: PACKAGE_TYPE_MAVEN,
    metadata: mavenMetadata(),
  };

  const xmlCodeBlock = `<dependency>
  <groupId>appGroup</groupId>
  <artifactId>appName</artifactId>
  <version>appVersion</version>
</dependency>`;
  const mavenCommandStr = 'mvn install';
  const mavenSetupXml = `<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>${packageEntity.mavenUrl}</url>
  </repository>
</repositories>

<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>${packageEntity.mavenUrl}</url>
  </repository>

  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>${packageEntity.mavenUrl}</url>
  </snapshotRepository>
</distributionManagement>`;
  const gradleGroovyInstallCommandText = `implementation 'appGroup:appName:appVersion'`;
  const gradleGroovyAddSourceCommandText = `maven {
  url '${packageEntity.mavenUrl}'
}`;
  const gradleKotlinInstallCommandText = `implementation("appGroup:appName:appVersion")`;
  const gradleKotlinAddSourceCommandText = `maven("${packageEntity.mavenUrl}")`;

  const findCodeInstructions = () => wrapper.findAllComponents(CodeInstructions);
  const findInstallationTitle = () => wrapper.findComponent(InstallationTitle);
  const findSetupDocsLink = () => wrapper.findComponent(GlLink);

  function createComponent({ data = {} } = {}) {
    wrapper = shallowMountExtended(MavenInstallation, {
      propsData: {
        packageEntity,
      },
      data() {
        return data;
      },
      stubs: {
        GlSprintf,
      },
    });
  }

  describe('install command switch', () => {
    it('has the installation title component', () => {
      createComponent();

      expect(findInstallationTitle().exists()).toBe(true);
      expect(findInstallationTitle().props()).toMatchObject({
        packageType: 'maven',
        options: [
          { value: 'maven', label: 'Maven XML' },
          { value: 'groovy', label: 'Gradle Groovy DSL' },
          { value: 'kotlin', label: 'Gradle Kotlin DSL' },
        ],
      });
    });

    it('on change event updates the instructions to show', async () => {
      createComponent();

      expect(findCodeInstructions().at(0).props('instruction')).toBe(xmlCodeBlock);
      findInstallationTitle().vm.$emit('change', 'groovy');

      await nextTick();

      expect(findCodeInstructions().at(0).props('instruction')).toBe(
        gradleGroovyInstallCommandText,
      );
    });
  });

  describe('maven', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders all the messages', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    describe('installation commands', () => {
      it('renders the correct xml block', () => {
        expect(findCodeInstructions().at(0).props()).toMatchObject({
          instruction: xmlCodeBlock,
          multiline: true,
          trackingAction: TRACKING_ACTION_COPY_MAVEN_XML,
        });
      });

      it('renders the correct maven command', () => {
        expect(findCodeInstructions().at(1).props()).toMatchObject({
          instruction: mavenCommandStr,
          multiline: false,
          trackingAction: TRACKING_ACTION_COPY_MAVEN_COMMAND,
        });
      });
    });

    describe('setup commands', () => {
      it('renders the correct xml block', () => {
        expect(findCodeInstructions().at(2).props()).toMatchObject({
          instruction: mavenSetupXml,
          multiline: true,
          trackingAction: TRACKING_ACTION_COPY_MAVEN_SETUP,
        });
      });

      it('has a setup link', () => {
        expect(findSetupDocsLink().attributes()).toMatchObject({
          href: MAVEN_HELP_PATH,
          target: '_blank',
        });
      });
    });
  });

  describe('groovy', () => {
    beforeEach(() => {
      createComponent({ data: { instructionType: 'groovy' } });
    });

    it('renders all the messages', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    describe('installation commands', () => {
      it('renders the gradle install command', () => {
        expect(findCodeInstructions().at(0).props()).toMatchObject({
          instruction: gradleGroovyInstallCommandText,
          multiline: false,
          trackingAction: TRACKING_ACTION_COPY_GRADLE_INSTALL_COMMAND,
        });
      });
    });

    describe('setup commands', () => {
      it('renders the correct gradle command', () => {
        expect(findCodeInstructions().at(1).props()).toMatchObject({
          instruction: gradleGroovyAddSourceCommandText,
          multiline: true,
          trackingAction: TRACKING_ACTION_COPY_GRADLE_ADD_TO_SOURCE_COMMAND,
        });
      });
    });
  });

  describe('kotlin', () => {
    beforeEach(() => {
      createComponent({ data: { instructionType: 'kotlin' } });
    });

    it('renders all the messages', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    describe('installation commands', () => {
      it('renders the gradle install command', () => {
        expect(findCodeInstructions().at(0).props()).toMatchObject({
          instruction: gradleKotlinInstallCommandText,
          multiline: false,
          trackingAction: TRACKING_ACTION_COPY_KOTLIN_INSTALL_COMMAND,
        });
      });
    });

    describe('setup commands', () => {
      it('renders the correct gradle command', () => {
        expect(findCodeInstructions().at(1).props()).toMatchObject({
          instruction: gradleKotlinAddSourceCommandText,
          multiline: true,
          trackingAction: TRACKING_ACTION_COPY_KOTLIN_ADD_TO_SOURCE_COMMAND,
        });
      });
    });
  });
});

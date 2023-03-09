import { shallowMount } from '@vue/test-utils';
import { packageData } from 'jest/packages_and_registries/package_registry/mock_data';
import ComposerInstallation from '~/packages_and_registries/package_registry/components/details/composer_installation.vue';
import ConanInstallation from '~/packages_and_registries/package_registry/components/details/conan_installation.vue';
import InstallationCommands from '~/packages_and_registries/package_registry/components/details/installation_commands.vue';

import MavenInstallation from '~/packages_and_registries/package_registry/components/details/maven_installation.vue';
import NpmInstallation from '~/packages_and_registries/package_registry/components/details/npm_installation.vue';
import NugetInstallation from '~/packages_and_registries/package_registry/components/details/nuget_installation.vue';
import PypiInstallation from '~/packages_and_registries/package_registry/components/details/pypi_installation.vue';
import {
  PACKAGE_TYPE_CONAN,
  PACKAGE_TYPE_MAVEN,
  PACKAGE_TYPE_NPM,
  PACKAGE_TYPE_NUGET,
  PACKAGE_TYPE_PYPI,
  PACKAGE_TYPE_COMPOSER,
} from '~/packages_and_registries/package_registry/constants';

const conanPackage = { ...packageData(), packageType: PACKAGE_TYPE_CONAN };
const mavenPackage = { ...packageData(), packageType: PACKAGE_TYPE_MAVEN };
const npmPackage = { ...packageData(), packageType: PACKAGE_TYPE_NPM };
const nugetPackage = { ...packageData(), packageType: PACKAGE_TYPE_NUGET };
const pypiPackage = { ...packageData(), packageType: PACKAGE_TYPE_PYPI };
const composerPackage = { ...packageData(), packageType: PACKAGE_TYPE_COMPOSER };

describe('InstallationCommands', () => {
  let wrapper;

  function createComponent(propsData) {
    wrapper = shallowMount(InstallationCommands, {
      propsData,
    });
  }

  const npmInstallation = () => wrapper.findComponent(NpmInstallation);
  const mavenInstallation = () => wrapper.findComponent(MavenInstallation);
  const conanInstallation = () => wrapper.findComponent(ConanInstallation);
  const nugetInstallation = () => wrapper.findComponent(NugetInstallation);
  const pypiInstallation = () => wrapper.findComponent(PypiInstallation);
  const composerInstallation = () => wrapper.findComponent(ComposerInstallation);

  describe('installation instructions', () => {
    describe.each`
      packageEntity      | selector
      ${conanPackage}    | ${conanInstallation}
      ${mavenPackage}    | ${mavenInstallation}
      ${npmPackage}      | ${npmInstallation}
      ${nugetPackage}    | ${nugetInstallation}
      ${pypiPackage}     | ${pypiInstallation}
      ${composerPackage} | ${composerInstallation}
    `('renders', ({ packageEntity, selector }) => {
      it(`${packageEntity.packageType} instructions exist`, () => {
        createComponent({ packageEntity });

        expect(selector().exists()).toBe(true);
      });
    });
  });
});

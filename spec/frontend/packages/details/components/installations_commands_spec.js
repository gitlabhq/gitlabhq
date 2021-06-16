import { shallowMount } from '@vue/test-utils';
import ComposerInstallation from '~/packages/details/components/composer_installation.vue';
import ConanInstallation from '~/packages/details/components/conan_installation.vue';
import InstallationCommands from '~/packages/details/components/installation_commands.vue';

import MavenInstallation from '~/packages/details/components/maven_installation.vue';
import NpmInstallation from '~/packages/details/components/npm_installation.vue';
import NugetInstallation from '~/packages/details/components/nuget_installation.vue';
import PypiInstallation from '~/packages/details/components/pypi_installation.vue';
import TerraformInstallation from '~/packages_and_registries/infrastructure_registry/components/terraform_installation.vue';

import {
  conanPackage,
  mavenPackage,
  npmPackage,
  nugetPackage,
  pypiPackage,
  composerPackage,
  terraformModule,
} from '../../mock_data';

describe('InstallationCommands', () => {
  let wrapper;

  function createComponent(propsData) {
    wrapper = shallowMount(InstallationCommands, {
      propsData,
    });
  }

  const npmInstallation = () => wrapper.find(NpmInstallation);
  const mavenInstallation = () => wrapper.find(MavenInstallation);
  const conanInstallation = () => wrapper.find(ConanInstallation);
  const nugetInstallation = () => wrapper.find(NugetInstallation);
  const pypiInstallation = () => wrapper.find(PypiInstallation);
  const composerInstallation = () => wrapper.find(ComposerInstallation);
  const terraformInstallation = () => wrapper.findComponent(TerraformInstallation);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('installation instructions', () => {
    describe.each`
      packageEntity      | selector
      ${conanPackage}    | ${conanInstallation}
      ${mavenPackage}    | ${mavenInstallation}
      ${npmPackage}      | ${npmInstallation}
      ${nugetPackage}    | ${nugetInstallation}
      ${pypiPackage}     | ${pypiInstallation}
      ${composerPackage} | ${composerInstallation}
      ${terraformModule} | ${terraformInstallation}
    `('renders', ({ packageEntity, selector }) => {
      it(`${packageEntity.package_type} instructions exist`, () => {
        createComponent({ packageEntity });

        expect(selector()).toExist();
      });
    });
  });
});

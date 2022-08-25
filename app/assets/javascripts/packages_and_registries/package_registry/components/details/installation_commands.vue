<script>
import {
  PACKAGE_TYPE_CONAN,
  PACKAGE_TYPE_MAVEN,
  PACKAGE_TYPE_NPM,
  PACKAGE_TYPE_NUGET,
  PACKAGE_TYPE_PYPI,
  PACKAGE_TYPE_COMPOSER,
} from '~/packages_and_registries/package_registry/constants';
import ComposerInstallation from './composer_installation.vue';
import ConanInstallation from './conan_installation.vue';
import MavenInstallation from './maven_installation.vue';
import NpmInstallation from './npm_installation.vue';
import NugetInstallation from './nuget_installation.vue';
import PypiInstallation from './pypi_installation.vue';

const components = {
  [PACKAGE_TYPE_CONAN]: ConanInstallation,
  [PACKAGE_TYPE_MAVEN]: MavenInstallation,
  [PACKAGE_TYPE_NPM]: NpmInstallation,
  [PACKAGE_TYPE_NUGET]: NugetInstallation,
  [PACKAGE_TYPE_PYPI]: PypiInstallation,
  [PACKAGE_TYPE_COMPOSER]: ComposerInstallation,
};

export default {
  name: 'InstallationCommands',
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
  },
  computed: {
    installationComponent() {
      return components[this.packageEntity.packageType];
    },
  },
};
</script>

<template>
  <div v-if="installationComponent">
    <component :is="installationComponent" :package-entity="packageEntity" />
  </div>
</template>

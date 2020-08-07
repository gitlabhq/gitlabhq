import { s__ } from '~/locale';

export const TrackingLabels = {
  CODE_INSTRUCTION: 'code_instruction',
  CONAN_INSTALLATION: 'conan_installation',
  MAVEN_INSTALLATION: 'maven_installation',
  NPM_INSTALLATION: 'npm_installation',
  NUGET_INSTALLATION: 'nuget_installation',
  PYPI_INSTALLATION: 'pypi_installation',
};

export const TrackingActions = {
  INSTALLATION: 'installation',
  REGISTRY_SETUP: 'registry_setup',

  COPY_CONAN_COMMAND: 'copy_conan_command',
  COPY_CONAN_SETUP_COMMAND: 'copy_conan_setup_command',

  COPY_MAVEN_XML: 'copy_maven_xml',
  COPY_MAVEN_COMMAND: 'copy_maven_command',
  COPY_MAVEN_SETUP: 'copy_maven_setup_xml',

  COPY_NPM_INSTALL_COMMAND: 'copy_npm_install_command',
  COPY_NPM_SETUP_COMMAND: 'copy_npm_setup_command',

  COPY_YARN_INSTALL_COMMAND: 'copy_yarn_install_command',
  COPY_YARN_SETUP_COMMAND: 'copy_yarn_setup_command',

  COPY_NUGET_INSTALL_COMMAND: 'copy_nuget_install_command',
  COPY_NUGET_SETUP_COMMAND: 'copy_nuget_setup_command',

  COPY_PIP_INSTALL_COMMAND: 'copy_pip_install_command',
  COPY_PYPI_SETUP_COMMAND: 'copy_pypi_setup_command',
};

export const NpmManager = {
  NPM: 'npm',
  YARN: 'yarn',
};

export const FETCH_PACKAGE_VERSIONS_ERROR = s__(
  'PackageRegistry|Unable to fetch package version information.',
);

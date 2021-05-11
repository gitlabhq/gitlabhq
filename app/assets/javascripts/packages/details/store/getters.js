import { PackageType } from '../../shared/constants';
import { getPackageTypeLabel } from '../../shared/utils';
import { NpmManager } from '../constants';

export const packagePipeline = ({ packageEntity }) => {
  return packageEntity?.pipeline || null;
};

export const packageTypeDisplay = ({ packageEntity }) => {
  return getPackageTypeLabel(packageEntity.package_type);
};

export const packageIcon = ({ packageEntity }) => {
  if (packageEntity.package_type === PackageType.NUGET) {
    return packageEntity.nuget_metadatum?.icon_url || null;
  }

  return null;
};

export const conanInstallationCommand = ({ packageEntity }) => {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  return `conan install ${packageEntity.name} --remote=gitlab`;
};

export const conanSetupCommand = ({ conanPath }) =>
  // eslint-disable-next-line @gitlab/require-i18n-strings
  `conan remote add gitlab ${conanPath}`;

export const mavenInstallationXml = ({ packageEntity = {} }) => {
  const {
    app_group: appGroup = '',
    app_name: appName = '',
    app_version: appVersion = '',
  } = packageEntity.maven_metadatum;

  return `<dependency>
  <groupId>${appGroup}</groupId>
  <artifactId>${appName}</artifactId>
  <version>${appVersion}</version>
</dependency>`;
};

export const mavenInstallationCommand = ({ packageEntity = {} }) => {
  const {
    app_group: group = '',
    app_name: name = '',
    app_version: version = '',
  } = packageEntity.maven_metadatum;

  return `mvn dependency:get -Dartifact=${group}:${name}:${version}`;
};

export const mavenSetupXml = ({ mavenPath }) => `<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>${mavenPath}</url>
  </repository>
</repositories>

<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>${mavenPath}</url>
  </repository>

  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>${mavenPath}</url>
  </snapshotRepository>
</distributionManagement>`;

export const npmInstallationCommand = ({ packageEntity }) => (type = NpmManager.NPM) => {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  const instruction = type === NpmManager.NPM ? 'npm i' : 'yarn add';

  return `${instruction} ${packageEntity.name}`;
};

export const npmSetupCommand = ({ packageEntity, npmPath }) => (type = NpmManager.NPM) => {
  const scope = packageEntity.name.substring(0, packageEntity.name.indexOf('/'));

  if (type === NpmManager.NPM) {
    return `echo ${scope}:registry=${npmPath}/ >> .npmrc`;
  }

  return `echo \\"${scope}:registry\\" \\"${npmPath}/\\" >> .yarnrc`;
};

export const nugetInstallationCommand = ({ packageEntity }) =>
  `nuget install ${packageEntity.name} -Source "GitLab"`;

export const nugetSetupCommand = ({ nugetPath }) =>
  `nuget source Add -Name "GitLab" -Source "${nugetPath}" -UserName <your_username> -Password <your_token>`;

export const pypiPipCommand = ({ pypiPath, packageEntity }) =>
  // eslint-disable-next-line @gitlab/require-i18n-strings
  `pip install ${packageEntity.name} --extra-index-url ${pypiPath}`;

export const pypiSetupCommand = ({ pypiSetupPath }) => `[gitlab]
repository = ${pypiSetupPath}
username = __token__
password = <your personal access token>`;

export const composerRegistryInclude = ({ composerPath, composerConfigRepositoryName }) =>
  // eslint-disable-next-line @gitlab/require-i18n-strings
  `composer config repositories.${composerConfigRepositoryName} '{"type": "composer", "url": "${composerPath}"}'`;

export const composerPackageInclude = ({ packageEntity }) =>
  // eslint-disable-next-line @gitlab/require-i18n-strings
  `composer req ${[packageEntity.name]}:${packageEntity.version}`;

export const gradleGroovyInstalCommand = ({ packageEntity }) => {
  const {
    app_group: group = '',
    app_name: name = '',
    app_version: version = '',
  } = packageEntity.maven_metadatum;
  // eslint-disable-next-line @gitlab/require-i18n-strings
  return `implementation '${group}:${name}:${version}'`;
};

export const gradleGroovyAddSourceCommand = ({ mavenPath }) =>
  // eslint-disable-next-line @gitlab/require-i18n-strings
  `maven {
  url '${mavenPath}'
}`;

export const gradleKotlinInstalCommand = ({ packageEntity }) => {
  const {
    app_group: group = '',
    app_name: name = '',
    app_version: version = '',
  } = packageEntity.maven_metadatum;
  return `implementation("${group}:${name}:${version}")`;
};

export const gradleKotlinAddSourceCommand = ({ mavenPath }) => `maven("${mavenPath}")`;

export const groupExists = ({ groupListUrl }) => groupListUrl.length > 0;

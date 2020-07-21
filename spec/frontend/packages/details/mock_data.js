import { formatDate } from '~/lib/utils/datetime_utility';
import { orderBy } from 'lodash';

export const registryUrl = 'foo/registry';

export const mavenMetadata = {
  app_group: 'com.test.package.app',
  app_name: 'test-package-app',
  app_version: '1.0.0',
};

export const generateMavenCommand = ({
  app_group: appGroup = '',
  app_name: appName = '',
  app_version: appVersion = '',
}) => `mvn dependency:get -Dartifact=${appGroup}:${appName}:${appVersion}`;

export const generateXmlCodeBlock = ({
  app_group: appGroup = '',
  app_name: appName = '',
  app_version: appVersion = '',
}) => `<dependency>
  <groupId>${appGroup}</groupId>
  <artifactId>${appName}</artifactId>
  <version>${appVersion}</version>
</dependency>`;

export const generateMavenSetupXml = () => `<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>${registryUrl}</url>
  </repository>
</repositories>

<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>${registryUrl}</url>
  </repository>

  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>${registryUrl}</url>
  </snapshotRepository>
</distributionManagement>`;

const generateCommonPackageInformation = packageEntity => [
  {
    label: 'Version',
    value: packageEntity.version,
    order: 2,
  },
  {
    label: 'Created on',
    value: formatDate(packageEntity.created_at),
    order: 5,
  },
  {
    label: 'Updated at',
    value: formatDate(packageEntity.updated_at),
    order: 6,
  },
];

export const generateStandardPackageInformation = packageEntity => [
  {
    label: 'Name',
    value: packageEntity.name,
    order: 1,
  },
  ...generateCommonPackageInformation(packageEntity),
];

export const generateConanInformation = conanPackage => [
  {
    label: 'Recipe',
    value: conanPackage.recipe,
    order: 1,
  },
  ...generateCommonPackageInformation(conanPackage),
];

export const generateNugetInformation = nugetPackage =>
  orderBy(
    [
      ...generateCommonPackageInformation(nugetPackage),
      {
        label: 'Name',
        value: nugetPackage.name,
        order: 1,
      },
      {
        label: 'Project URL',
        value: nugetPackage.nuget_metadatum.project_url,
        order: 3,
        type: 'link',
      },
      {
        label: 'License URL',
        value: nugetPackage.nuget_metadatum.license_url,
        order: 4,
        type: 'link',
      },
    ],
    ['order'],
  );

export const pypiSetupCommandStr = `[gitlab]
repository = foo
username = __token__
password = <your personal access token>`;

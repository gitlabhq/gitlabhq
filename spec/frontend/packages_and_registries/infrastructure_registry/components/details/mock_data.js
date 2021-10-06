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

export const pypiSetupCommandStr = `[gitlab]
repository = foo
username = __token__
password = <your personal access token>`;

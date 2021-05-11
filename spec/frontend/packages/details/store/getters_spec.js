import { NpmManager } from '~/packages/details/constants';
import {
  conanInstallationCommand,
  conanSetupCommand,
  packagePipeline,
  packageTypeDisplay,
  packageIcon,
  mavenInstallationXml,
  mavenInstallationCommand,
  mavenSetupXml,
  npmInstallationCommand,
  npmSetupCommand,
  nugetInstallationCommand,
  nugetSetupCommand,
  pypiPipCommand,
  pypiSetupCommand,
  composerRegistryInclude,
  composerPackageInclude,
  groupExists,
  gradleGroovyInstalCommand,
  gradleGroovyAddSourceCommand,
  gradleKotlinInstalCommand,
  gradleKotlinAddSourceCommand,
} from '~/packages/details/store/getters';
import {
  conanPackage,
  npmPackage,
  nugetPackage,
  mockPipelineInfo,
  mavenPackage as packageWithoutBuildInfo,
  pypiPackage,
  rubygemsPackage,
} from '../../mock_data';
import {
  generateMavenCommand,
  generateXmlCodeBlock,
  generateMavenSetupXml,
  registryUrl,
  pypiSetupCommandStr,
} from '../mock_data';

describe('Getters PackageDetails Store', () => {
  let state;

  const defaultState = {
    packageEntity: packageWithoutBuildInfo,
    conanPath: registryUrl,
    mavenPath: registryUrl,
    npmPath: registryUrl,
    nugetPath: registryUrl,
    pypiPath: registryUrl,
  };

  const setupState = (testState = {}) => {
    state = {
      ...defaultState,
      ...testState,
    };
  };

  const conanInstallationCommandStr = `conan install ${conanPackage.name} --remote=gitlab`;
  const conanSetupCommandStr = `conan remote add gitlab ${registryUrl}`;

  const mavenCommandStr = generateMavenCommand(packageWithoutBuildInfo.maven_metadatum);
  const mavenInstallationXmlBlock = generateXmlCodeBlock(packageWithoutBuildInfo.maven_metadatum);
  const mavenSetupXmlBlock = generateMavenSetupXml();

  const npmInstallStr = `npm i ${npmPackage.name}`;
  const npmSetupStr = `echo @Test:registry=${registryUrl}/ >> .npmrc`;
  const yarnInstallStr = `yarn add ${npmPackage.name}`;
  const yarnSetupStr = `echo \\"@Test:registry\\" \\"${registryUrl}/\\" >> .yarnrc`;

  const nugetInstallationCommandStr = `nuget install ${nugetPackage.name} -Source "GitLab"`;
  const nugetSetupCommandStr = `nuget source Add -Name "GitLab" -Source "${registryUrl}" -UserName <your_username> -Password <your_token>`;

  const pypiPipCommandStr = `pip install ${pypiPackage.name} --extra-index-url ${registryUrl}`;
  const composerRegistryIncludeStr =
    'composer config repositories.gitlab.com/123 \'{"type": "composer", "url": "foo"}\'';
  const composerPackageIncludeStr = `composer req ${[packageWithoutBuildInfo.name]}:${
    packageWithoutBuildInfo.version
  }`;

  describe('packagePipeline', () => {
    it('should return the pipeline info when pipeline exists', () => {
      setupState({
        packageEntity: {
          ...npmPackage,
          pipeline: mockPipelineInfo,
        },
      });

      expect(packagePipeline(state)).toEqual(mockPipelineInfo);
    });

    it('should return null when build_info does not exist', () => {
      setupState();

      expect(packagePipeline(state)).toBe(null);
    });
  });

  describe('packageTypeDisplay', () => {
    describe.each`
      packageEntity              | expectedResult
      ${conanPackage}            | ${'Conan'}
      ${packageWithoutBuildInfo} | ${'Maven'}
      ${npmPackage}              | ${'npm'}
      ${nugetPackage}            | ${'NuGet'}
      ${pypiPackage}             | ${'PyPI'}
      ${rubygemsPackage}         | ${'RubyGems'}
    `(`package type`, ({ packageEntity, expectedResult }) => {
      beforeEach(() => setupState({ packageEntity }));

      it(`${packageEntity.package_type} should show as ${expectedResult}`, () => {
        expect(packageTypeDisplay(state)).toBe(expectedResult);
      });
    });
  });

  describe('packageIcon', () => {
    describe('nuget packages', () => {
      it('should return nuget package icon', () => {
        setupState({ packageEntity: nugetPackage });

        expect(packageIcon(state)).toBe(nugetPackage.nuget_metadatum.icon_url);
      });

      it('should return null when nuget package does not have an icon', () => {
        setupState({ packageEntity: { ...nugetPackage, nuget_metadatum: {} } });

        expect(packageIcon(state)).toBe(null);
      });
    });

    it('should not find icons for other package types', () => {
      setupState({ packageEntity: npmPackage });

      expect(packageIcon(state)).toBe(null);
    });
  });

  describe('conan string getters', () => {
    it('gets the correct conanInstallationCommand', () => {
      setupState({ packageEntity: conanPackage });

      expect(conanInstallationCommand(state)).toBe(conanInstallationCommandStr);
    });

    it('gets the correct conanSetupCommand', () => {
      setupState({ packageEntity: conanPackage });

      expect(conanSetupCommand(state)).toBe(conanSetupCommandStr);
    });
  });

  describe('maven string getters', () => {
    it('gets the correct mavenInstallationXml', () => {
      setupState();

      expect(mavenInstallationXml(state)).toBe(mavenInstallationXmlBlock);
    });

    it('gets the correct mavenInstallationCommand', () => {
      setupState();

      expect(mavenInstallationCommand(state)).toBe(mavenCommandStr);
    });

    it('gets the correct mavenSetupXml', () => {
      setupState();

      expect(mavenSetupXml(state)).toBe(mavenSetupXmlBlock);
    });
  });

  describe('npm string getters', () => {
    it('gets the correct npmInstallationCommand for npm', () => {
      setupState({ packageEntity: npmPackage });

      expect(npmInstallationCommand(state)(NpmManager.NPM)).toBe(npmInstallStr);
    });

    it('gets the correct npmSetupCommand for npm', () => {
      setupState({ packageEntity: npmPackage });

      expect(npmSetupCommand(state)(NpmManager.NPM)).toBe(npmSetupStr);
    });

    it('gets the correct npmInstallationCommand for Yarn', () => {
      setupState({ packageEntity: npmPackage });

      expect(npmInstallationCommand(state)(NpmManager.YARN)).toBe(yarnInstallStr);
    });

    it('gets the correct npmSetupCommand for Yarn', () => {
      setupState({ packageEntity: npmPackage });

      expect(npmSetupCommand(state)(NpmManager.YARN)).toBe(yarnSetupStr);
    });
  });

  describe('nuget string getters', () => {
    it('gets the correct nugetInstallationCommand', () => {
      setupState({ packageEntity: nugetPackage });

      expect(nugetInstallationCommand(state)).toBe(nugetInstallationCommandStr);
    });

    it('gets the correct nugetSetupCommand', () => {
      setupState({ packageEntity: nugetPackage });

      expect(nugetSetupCommand(state)).toBe(nugetSetupCommandStr);
    });
  });

  describe('pypi string getters', () => {
    it('gets the correct pypiPipCommand', () => {
      setupState({ packageEntity: pypiPackage });

      expect(pypiPipCommand(state)).toBe(pypiPipCommandStr);
    });

    it('gets the correct pypiSetupCommand', () => {
      setupState({ pypiSetupPath: 'foo' });

      expect(pypiSetupCommand(state)).toBe(pypiSetupCommandStr);
    });
  });

  describe('composer string getters', () => {
    it('gets the correct composerRegistryInclude command', () => {
      setupState({ composerPath: 'foo', composerConfigRepositoryName: 'gitlab.com/123' });

      expect(composerRegistryInclude(state)).toBe(composerRegistryIncludeStr);
    });

    it('gets the correct composerPackageInclude command', () => {
      setupState();

      expect(composerPackageInclude(state)).toBe(composerPackageIncludeStr);
    });
  });

  describe('gradle groovy string getters', () => {
    it('gets the correct gradleGroovyInstalCommand', () => {
      setupState();

      expect(gradleGroovyInstalCommand(state)).toMatchInlineSnapshot(
        `"implementation 'com.test.app:test-app:1.0-SNAPSHOT'"`,
      );
    });

    it('gets the correct gradleGroovyAddSourceCommand', () => {
      setupState();

      expect(gradleGroovyAddSourceCommand(state)).toMatchInlineSnapshot(`
        "maven {
          url 'foo/registry'
        }"
      `);
    });
  });

  describe('gradle kotlin string getters', () => {
    it('gets the correct gradleKotlinInstalCommand', () => {
      setupState();

      expect(gradleKotlinInstalCommand(state)).toMatchInlineSnapshot(
        `"implementation(\\"com.test.app:test-app:1.0-SNAPSHOT\\")"`,
      );
    });

    it('gets the correct gradleKotlinAddSourceCommand', () => {
      setupState();

      expect(gradleKotlinAddSourceCommand(state)).toMatchInlineSnapshot(
        `"maven(\\"foo/registry\\")"`,
      );
    });
  });

  describe('check if group', () => {
    it('is set', () => {
      setupState({ groupListUrl: '/groups/composer/-/packages' });

      expect(groupExists(state)).toBe(true);
    });

    it('is not set', () => {
      setupState({ groupListUrl: '' });

      expect(groupExists(state)).toBe(false);
    });
  });
});

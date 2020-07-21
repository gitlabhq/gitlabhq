import { generateConanRecipe, generatePackageInfo } from '~/packages/details/utils';
import { conanPackage, mavenPackage, npmPackage, nugetPackage } from '../mock_data';
import {
  generateConanInformation,
  generateStandardPackageInformation,
  generateNugetInformation,
} from './mock_data';

describe('Package detail utils', () => {
  describe('generating information', () => {
    describe('conan packages', () => {
      const conanInformation = generateConanInformation(conanPackage);

      it('correctly generates the conan information', () => {
        const info = generatePackageInfo(conanPackage);

        expect(info).toEqual(conanInformation);
      });

      describe('generating recipe', () => {
        it('correctly generates the conan recipe', () => {
          const recipe = generateConanRecipe(conanPackage);

          expect(recipe).toEqual(conanPackage.recipe);
        });

        it('returns an empty recipe when no information is supplied', () => {
          const recipe = generateConanRecipe({});

          expect(recipe).toEqual('/@/');
        });

        it('recipe returns empty strings for missing metadata', () => {
          const recipe = generateConanRecipe({ name: 'foo', version: '0.0.1' });

          expect(recipe).toEqual('foo/0.0.1@/');
        });
      });
    });

    describe('npm packages', () => {
      const npmInformation = generateStandardPackageInformation(npmPackage);

      it('correctly generates the npm information', () => {
        const info = generatePackageInfo(npmPackage);

        expect(info).toEqual(npmInformation);
      });
    });

    describe('maven packages', () => {
      const mavenInformation = generateStandardPackageInformation(mavenPackage);

      it('correctly generates the maven information', () => {
        const info = generatePackageInfo(mavenPackage);

        expect(info).toEqual(mavenInformation);
      });
    });

    describe('nuget packages', () => {
      const nugetInformation = generateNugetInformation(nugetPackage);

      it('correctly generates the nuget information', () => {
        const info = generatePackageInfo(nugetPackage);

        expect(info).toEqual(nugetInformation);
      });
    });
  });
});

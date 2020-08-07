import { generateConanRecipe } from '~/packages/details/utils';
import { conanPackage } from '../mock_data';

describe('Package detail utils', () => {
  describe('generateConanRecipe', () => {
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

      expect(recipe).toBe('foo/0.0.1@/');
    });
  });
});

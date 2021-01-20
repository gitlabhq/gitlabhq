import { getRulesWithTraversal } from '~/ide/lib/editorconfig/parser';
import { exampleConfigs, exampleFiles } from './mock_data';

describe('~/ide/lib/editorconfig/parser', () => {
  const getExampleConfigContent = (path) =>
    Promise.resolve(exampleConfigs.find((x) => x.path === path)?.content);

  describe('getRulesWithTraversal', () => {
    it.each(exampleFiles)(
      'traverses through all editorconfig files in parent directories (until root=true is hit) and finds rules for this file (case %#)',
      ({ path, rules }) => {
        return getRulesWithTraversal(path, getExampleConfigContent).then((result) => {
          expect(result).toEqual(rules);
        });
      },
    );
  });
});

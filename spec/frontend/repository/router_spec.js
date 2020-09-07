import IndexPage from '~/repository/pages/index.vue';
import TreePage from '~/repository/pages/tree.vue';
import createRouter from '~/repository/router';

describe('Repository router spec', () => {
  it.each`
    path                           | branch          | component    | componentName
    ${'/'}                         | ${'master'}     | ${IndexPage} | ${'IndexPage'}
    ${'/tree/master'}              | ${'master'}     | ${TreePage}  | ${'TreePage'}
    ${'/tree/feat(test)'}          | ${'feat(test)'} | ${TreePage}  | ${'TreePage'}
    ${'/-/tree/master'}            | ${'master'}     | ${TreePage}  | ${'TreePage'}
    ${'/-/tree/master/app/assets'} | ${'master'}     | ${TreePage}  | ${'TreePage'}
    ${'/-/tree/123/app/assets'}    | ${'master'}     | ${null}      | ${'null'}
  `('sets component as $componentName for path "$path"', ({ path, component, branch }) => {
    const router = createRouter('', branch);

    const componentsForRoute = router.getMatchedComponents(path);

    expect(componentsForRoute.length).toBe(component ? 1 : 0);

    if (component) {
      expect(componentsForRoute).toContain(component);
    }
  });
});

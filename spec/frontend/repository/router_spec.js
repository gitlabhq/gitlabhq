import IndexPage from '~/repository/pages/index.vue';
import TreePage from '~/repository/pages/tree.vue';
import createRouter from '~/repository/router';

describe('Repository router spec', () => {
  it.each`
    path                           | component    | componentName
    ${'/'}                         | ${IndexPage} | ${'IndexPage'}
    ${'/-/tree/master'}            | ${TreePage}  | ${'TreePage'}
    ${'/-/tree/master/app/assets'} | ${TreePage}  | ${'TreePage'}
    ${'/-/tree/123/app/assets'}    | ${null}      | ${'null'}
  `('sets component as $componentName for path "$path"', ({ path, component }) => {
    const router = createRouter('', 'master');

    const componentsForRoute = router.getMatchedComponents(path);

    expect(componentsForRoute.length).toBe(component ? 1 : 0);

    if (component) {
      expect(componentsForRoute).toContain(component);
    }
  });
});

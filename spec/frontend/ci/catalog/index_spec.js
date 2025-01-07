import { initCatalog } from '~/ci/catalog/';
import * as Router from '~/ci/catalog/router';
import CiResourcesPage from '~/ci/catalog/components/pages/ci_resources_page.vue';

describe('~/ci/catalog/index', () => {
  describe('initCatalog', () => {
    const SELECTOR = 'SELECTOR';

    let el;
    let component;
    const baseRoute = '/explore/catalog';

    const createElement = () => {
      el = document.createElement('div');
      el.id = SELECTOR;
      el.dataset.ciCatalogPath = baseRoute;
      document.body.appendChild(el);
    };

    afterEach(() => {
      el = null;
    });

    describe('when the element exists', () => {
      beforeEach(() => {
        createElement();
        jest.spyOn(Router, 'createRouter');
        component = initCatalog(`#${SELECTOR}`);
      });

      it('returns a Vue Instance', () => {
        expect(component.$options.name).toBe('GlobalCatalog');
      });

      it('creates a router with the received base path and component', () => {
        expect(Router.createRouter).toHaveBeenCalledTimes(1);
        expect(Router.createRouter).toHaveBeenCalledWith(baseRoute, CiResourcesPage);
      });
    });

    describe('When the element does not exist', () => {
      it('returns `null`', () => {
        expect(initCatalog('foo')).toBe(null);
      });
    });
  });
});

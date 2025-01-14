import { createWrapper } from '@vue/test-utils';
import { initCatalog } from '~/ci/catalog';
import * as Router from '~/ci/catalog/router';
import GlobalCatalog from '~/ci/catalog/global_catalog.vue';
import CiResourcesPage from '~/ci/catalog/components/pages/ci_resources_page.vue';

describe('~/ci/catalog/index', () => {
  describe('initCatalog', () => {
    const SELECTOR = 'SELECTOR';

    let el;
    let wrapper;
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

    const findGlobalCatalog = () => wrapper.findComponent(GlobalCatalog);

    describe('when the element exists', () => {
      beforeEach(() => {
        createElement();
        jest.spyOn(Router, 'createRouter');
        wrapper = createWrapper(initCatalog(`#${SELECTOR}`));
      });

      it('renders the GlobalCatalog component', () => {
        expect(findGlobalCatalog().exists()).toBe(true);
      });

      it('creates a router with the received base path and component', () => {
        expect(Router.createRouter).toHaveBeenCalledTimes(1);
        expect(Router.createRouter).toHaveBeenCalledWith(baseRoute, CiResourcesPage);
      });
    });

    describe('When the element does not exist', () => {
      it('returns `null`', () => {
        expect(initCatalog('foo')).toBeNull();
      });
    });
  });
});

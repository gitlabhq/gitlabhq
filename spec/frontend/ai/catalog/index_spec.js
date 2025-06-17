import { createWrapper } from '@vue/test-utils';

import { initAiCatalog } from '~/ai/catalog/index';
import AiCatalogApp from '~/ai/catalog/ai_catalog_app.vue';
import * as Router from '~/ai/catalog/router';

describe('AI Catalog Index', () => {
  let mockElement;
  let wrapper;

  const findAiCatalog = () => wrapper.findComponent(AiCatalogApp);

  afterEach(() => {
    mockElement = null;
  });

  describe('initAiCatalog', () => {
    beforeEach(() => {
      mockElement = document.createElement('div');
      mockElement.id = 'js-ai-catalog';
      mockElement.dataset.aiCatalogIndexPath = '/ai/catalog';
      document.body.appendChild(mockElement);

      jest.spyOn(Router, 'createRouter');

      wrapper = createWrapper(initAiCatalog(`#${mockElement.id}`));
    });

    it('renders the AiCatalog component', () => {
      expect(findAiCatalog().exists()).toBe(true);
    });

    it('creates router with correct base path', () => {
      initAiCatalog();

      expect(Router.createRouter).toHaveBeenCalledWith('/ai/catalog');
    });
  });

  describe('when the element does not exist', () => {
    it('returns `null`', () => {
      expect(initAiCatalog('foo')).toBeNull();
    });
  });
});

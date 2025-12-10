import { GlTab, GlTabs } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemsSavedViewsSelectors from '~/work_items/components/shared/work_items_saved_views_selectors.vue';

describe('WorkItemsSavedViewsSelectors', () => {
  let wrapper;

  const createComponent = ({ pageParams = {} } = {}) => {
    wrapper = shallowMountExtended(WorkItemsSavedViewsSelectors, {
      propsData: { pageParams },
      slots: {
        'header-area': '<div data-testid="header-area-slot">Header Area</div>',
      },
      stubs: {
        GlTabs,
        GlTab,
      },
    });
  };

  const findDefaultViewSelector = () => wrapper.findByTestId('saved-views-default-view-selector');

  describe('default view', () => {
    it('renders the default view selector with correct title', () => {
      createComponent();
      expect(findDefaultViewSelector().text()).toBe('All items');
    });
  });
});

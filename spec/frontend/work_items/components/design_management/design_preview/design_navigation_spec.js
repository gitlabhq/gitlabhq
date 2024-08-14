import { GlButtonGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DesignNavigation from '~/work_items/components/design_management/design_preview/design_navigation.vue';
import { ROUTES } from '~/work_items/constants';
import { Mousetrap } from '~/lib/mousetrap';
import waitForPromises from 'helpers/wait_for_promises';
import { mockDesign, mockDesign2 } from '../mock_data';

const push = jest.fn();
const $router = {
  push,
};

const $route = {
  path: '/designs/design-2',
  query: {},
};

describe('Design management pagination component', () => {
  let wrapper;

  function createComponent({ propsData = {} } = {}) {
    wrapper = shallowMount(DesignNavigation, {
      propsData: {
        filename: mockDesign.filename,
        allDesigns: [mockDesign, mockDesign2],
        ...propsData,
      },
      mocks: {
        $router,
        $route,
      },
    });
  }

  const findGlButtonGroup = () => wrapper.findComponent(GlButtonGroup);

  it('hides components when designs are empty', () => {
    createComponent({ propsData: { allDesigns: [] } });

    expect(findGlButtonGroup().exists()).toBe(false);
  });

  it('renders navigation buttons', () => {
    createComponent();

    expect(findGlButtonGroup().exists()).toBe(true);
  });

  describe('keyboard buttons navigation', () => {
    it('routes to previous design on Left button', async () => {
      createComponent({ propsData: { filename: mockDesign2.filename } });
      await waitForPromises();

      Mousetrap.trigger('left');
      expect(push).toHaveBeenCalledWith({
        name: ROUTES.design,
        params: { id: mockDesign.filename },
        query: {},
      });
    });

    it('routes to next design on Right button', async () => {
      createComponent({ propsData: { filename: mockDesign.filename } });
      await waitForPromises();

      Mousetrap.trigger('right');
      expect(push).toHaveBeenCalledWith({
        name: ROUTES.design,
        params: { id: mockDesign2.filename },
        query: {},
      });
    });
  });
});

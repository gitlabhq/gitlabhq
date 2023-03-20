/* global Mousetrap */
import 'mousetrap';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DesignNavigation from '~/design_management/components/toolbar/design_navigation.vue';
import { DESIGN_ROUTE_NAME } from '~/design_management/router/constants';

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

  function createComponent() {
    wrapper = shallowMount(DesignNavigation, {
      propsData: {
        id: '2',
      },
      mocks: {
        $router,
        $route,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  it('hides components when designs are empty', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders navigation buttons', async () => {
    // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
    // eslint-disable-next-line no-restricted-syntax
    wrapper.setData({
      designCollection: { designs: [{ id: '1' }, { id: '2' }] },
    });

    await nextTick();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('keyboard buttons navigation', () => {
    beforeEach(() => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        designCollection: { designs: [{ filename: '1' }, { filename: '2' }, { filename: '3' }] },
      });
    });

    it('routes to previous design on Left button', () => {
      Mousetrap.trigger('left');
      expect(push).toHaveBeenCalledWith({
        name: DESIGN_ROUTE_NAME,
        params: { id: '1' },
        query: {},
      });
    });

    it('routes to next design on Right button', () => {
      Mousetrap.trigger('right');
      expect(push).toHaveBeenCalledWith({
        name: DESIGN_ROUTE_NAME,
        params: { id: '3' },
        query: {},
      });
    });
  });
});

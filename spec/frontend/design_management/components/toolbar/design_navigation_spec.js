/* global Mousetrap */
import 'mousetrap';
import { shallowMount } from '@vue/test-utils';
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

  afterEach(() => {
    wrapper.destroy();
  });

  it('hides components when designs are empty', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders navigation buttons', () => {
    wrapper.setData({
      designCollection: { designs: [{ id: '1' }, { id: '2' }] },
    });

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('keyboard buttons navigation', () => {
    beforeEach(() => {
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

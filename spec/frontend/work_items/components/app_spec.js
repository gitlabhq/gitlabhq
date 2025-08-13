import { shallowMount } from '@vue/test-utils';
import App from '~/work_items/components/app.vue';
import { ROUTES } from '~/work_items/constants';

describe('Work Items Application', () => {
  let wrapper;

  const DEFAULT_ROUTE_MOCK = {
    path: '/',
    name: ROUTES.index,
    params: {},
  };

  const createComponent = (routeMock = DEFAULT_ROUTE_MOCK) => {
    wrapper = shallowMount(App, {
      stubs: {
        'router-view': true,
      },
      mocks: {
        $route: routeMock,
      },
      propsData: {
        rootPageFullPath: 'gitlab-org/gitlab',
      },
    });
  };

  it('renders a component', () => {
    createComponent();

    expect(wrapper.exists()).toBe(true);
  });
});

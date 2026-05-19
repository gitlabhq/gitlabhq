import { GlBreadcrumb } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ServiceAccountsBreadcrumb from '~/service_accounts/components/service_accounts_breadcrumb.vue';

describe('ServiceAccountsBreadcrumb', () => {
  let wrapper;

  const findBreadcrumb = () => wrapper.findComponent(GlBreadcrumb);

  const createComponent = ({ $route = {}, props = { staticBreadcrumbs: [] } } = {}) => {
    wrapper = shallowMount(ServiceAccountsBreadcrumb, {
      mocks: {
        $route,
      },
      propsData: props,
    });
  };

  it('renders the root `Service Accounts` breadcrumb on Service Accounts page', () => {
    createComponent();

    expect(findBreadcrumb().props('items')).toEqual([{ text: 'Service accounts', to: '/' }]);
  });

  it('renders the `Personal access tokens` breadcrumb on access token page', () => {
    createComponent({ $route: { name: 'access_tokens', path: '/72/access_tokens' } });

    expect(findBreadcrumb().props('items')).toEqual([
      { text: 'Service accounts', to: '/' },
      { text: 'Personal access tokens', to: '/72/access_tokens' },
    ]);
  });

  it('should render the static breadcrumbs', () => {
    const staticBreadcrumb = { text: 'Static breadcrumb', href: '/static' };
    createComponent({
      props: {
        staticBreadcrumbs: [staticBreadcrumb],
      },
    });

    expect(findBreadcrumb().props('items')).toStrictEqual([
      staticBreadcrumb,
      { text: 'Service accounts', to: '/' },
    ]);
  });
});

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ObservabilityApp from '~/observability/components/observability_app.vue';

describe('Observability root app', () => {
  let wrapper;
  const replace = jest.fn();
  const $router = {
    replace,
  };
  const $route = {
    pathname: 'https://gitlab.com/gitlab-org/',
    query: { otherQuery: 100 },
  };

  const findIframe = () => wrapper.findByTestId('observability-ui-iframe');

  const TEST_IFRAME_SRC = 'https://observe.gitlab.com/9970/?groupId=14485840';

  const mountComponent = (route = $route) => {
    wrapper = shallowMountExtended(ObservabilityApp, {
      propsData: {
        observabilityIframeSrc: TEST_IFRAME_SRC,
      },
      mocks: {
        $router,
        $route: route,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render an iframe with observabilityIframeSrc as src', () => {
    mountComponent();
    const iframe = findIframe();
    expect(iframe.exists()).toBe(true);
    expect(iframe.attributes('src')).toBe(TEST_IFRAME_SRC);
  });

  it('should not call replace method from vue router if message event does not have url', () => {
    mountComponent();
    wrapper.vm.messageHandler({ data: 'some other data' });
    expect(replace).not.toHaveBeenCalled();
  });

  it.each`
    condition                                                  | origin                          | observability_path | url
    ${'message origin is different from iframe source origin'} | ${'https://example.com'}        | ${'/'}             | ${'/explore'}
    ${'path is same as before (observability_path)'}           | ${'https://observe.gitlab.com'} | ${'/foo?bar=test'} | ${'/foo?bar=test'}
  `(
    'should not call replace method from vue router if $condition',
    async ({ origin, observability_path, url }) => {
      mountComponent({ ...$route, query: { observability_path } });
      wrapper.vm.messageHandler({ data: { url }, origin });
      expect(replace).not.toHaveBeenCalled();
    },
  );

  it('should call replace method from vue router on messageHandle call', () => {
    mountComponent();
    wrapper.vm.messageHandler({ data: { url: '/explore' }, origin: 'https://observe.gitlab.com' });
    expect(replace).toHaveBeenCalled();
    expect(replace).toHaveBeenCalledWith({
      name: 'https://gitlab.com/gitlab-org/',
      query: {
        otherQuery: 100,
        observability_path: '/explore',
      },
    });
  });
});

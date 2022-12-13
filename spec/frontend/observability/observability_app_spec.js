import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ObservabilityApp from '~/observability/components/observability_app.vue';
import ObservabilitySkeleton from '~/observability/components/skeleton/index.vue';

import {
  MESSAGE_EVENT_TYPE,
  OBSERVABILITY_ROUTES,
  SKELETON_VARIANT,
} from '~/observability/constants';

import { darkModeEnabled } from '~/lib/utils/color_utils';

jest.mock('~/lib/utils/color_utils');

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

  const mockHandleSkeleton = jest.fn();

  const findIframe = () => wrapper.findByTestId('observability-ui-iframe');

  const TEST_IFRAME_SRC = 'https://observe.gitlab.com/9970/?groupId=14485840';

  const mountComponent = (route = $route) => {
    wrapper = shallowMountExtended(ObservabilityApp, {
      propsData: {
        observabilityIframeSrc: TEST_IFRAME_SRC,
      },
      stubs: {
        'observability-skeleton': ObservabilitySkeleton,
      },
      mocks: {
        $router,
        $route: route,
      },
    });
  };

  const dispatchMessageEvent = (message) =>
    window.dispatchEvent(new MessageEvent('message', message));

  afterEach(() => {
    wrapper.destroy();
  });

  describe('iframe src', () => {
    const TEST_USERNAME = 'test-user';

    beforeAll(() => {
      gon.current_username = TEST_USERNAME;
    });

    it('should render an iframe with observabilityIframeSrc, decorated with light theme and username', () => {
      darkModeEnabled.mockReturnValueOnce(false);
      mountComponent();
      const iframe = findIframe();

      expect(iframe.exists()).toBe(true);
      expect(iframe.attributes('src')).toBe(
        `${TEST_IFRAME_SRC}&theme=light&username=${TEST_USERNAME}`,
      );
    });

    it('should render an iframe with observabilityIframeSrc decorated with dark theme and username', () => {
      darkModeEnabled.mockReturnValueOnce(true);
      mountComponent();
      const iframe = findIframe();

      expect(iframe.exists()).toBe(true);
      expect(iframe.attributes('src')).toBe(
        `${TEST_IFRAME_SRC}&theme=dark&username=${TEST_USERNAME}`,
      );
    });
  });

  describe('iframe sandbox', () => {
    it('should render an iframe with sandbox attributes', () => {
      mountComponent();
      const iframe = findIframe();

      expect(iframe.exists()).toBe(true);
      expect(iframe.attributes('sandbox')).toBe('allow-same-origin allow-forms allow-scripts');
    });
  });

  describe('on GOUI_ROUTE_UPDATE', () => {
    it('should not call replace method from vue router if message event does not have url', () => {
      mountComponent();
      dispatchMessageEvent({
        type: MESSAGE_EVENT_TYPE.GOUI_ROUTE_UPDATE,
        payload: { data: 'some other data' },
      });
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
        dispatchMessageEvent({
          data: { type: MESSAGE_EVENT_TYPE.GOUI_ROUTE_UPDATE, payload: { url } },
          origin,
        });
        expect(replace).not.toHaveBeenCalled();
      },
    );

    it('should call replace method from vue router on message event callback', () => {
      mountComponent();

      dispatchMessageEvent({
        data: { type: MESSAGE_EVENT_TYPE.GOUI_ROUTE_UPDATE, payload: { url: '/explore' } },
        origin: 'https://observe.gitlab.com',
      });

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

  describe('on GOUI_LOADED', () => {
    beforeEach(() => {
      mountComponent();
      wrapper.vm.$refs.iframeSkeleton.handleSkeleton = mockHandleSkeleton;
    });
    it('should call handleSkeleton method', () => {
      dispatchMessageEvent({
        data: { type: MESSAGE_EVENT_TYPE.GOUI_LOADED },
        origin: 'https://observe.gitlab.com',
      });
      expect(mockHandleSkeleton).toHaveBeenCalled();
    });

    it('should not call handleSkeleton method if origin is different', () => {
      dispatchMessageEvent({
        data: { type: MESSAGE_EVENT_TYPE.GOUI_LOADED },
        origin: 'https://example.com',
      });
      expect(mockHandleSkeleton).not.toHaveBeenCalled();
    });

    it('should not call handleSkeleton method if event type is different', () => {
      dispatchMessageEvent({
        data: { type: 'UNKNOWN_EVENT' },
        origin: 'https://observe.gitlab.com',
      });
      expect(mockHandleSkeleton).not.toHaveBeenCalled();
    });
  });

  describe('skeleton variant', () => {
    it.each`
      pathDescription        | path                               | variant
      ${'dashboards'}        | ${OBSERVABILITY_ROUTES.DASHBOARDS} | ${SKELETON_VARIANT.DASHBOARDS}
      ${'explore'}           | ${OBSERVABILITY_ROUTES.EXPLORE}    | ${SKELETON_VARIANT.EXPLORE}
      ${'manage dashboards'} | ${OBSERVABILITY_ROUTES.MANAGE}     | ${SKELETON_VARIANT.MANAGE}
      ${'any other'}         | ${'unknown/route'}                 | ${SKELETON_VARIANT.DASHBOARDS}
    `('renders the $variant skeleton variant for $pathDescription path', ({ path, variant }) => {
      mountComponent({ ...$route, path });
      const props = wrapper.findComponent(ObservabilitySkeleton).props();

      expect(props.variant).toBe(variant);
    });
  });

  describe('on observability ui unmount', () => {
    it('should remove message event and should not call replace method from vue router', () => {
      mountComponent();
      wrapper.destroy();

      // testing event cleanup logic, should not call on messege event after component is destroyed

      dispatchMessageEvent({
        data: { type: MESSAGE_EVENT_TYPE.GOUI_ROUTE_UPDATE, payload: { url: '/explore' } },
        origin: 'https://observe.gitlab.com',
      });

      expect(replace).not.toHaveBeenCalled();
    });
  });
});

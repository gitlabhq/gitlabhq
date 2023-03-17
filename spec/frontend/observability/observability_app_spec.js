import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ObservabilityApp from '~/observability/components/observability_app.vue';
import ObservabilitySkeleton from '~/observability/components/skeleton/index.vue';
import {
  MESSAGE_EVENT_TYPE,
  INLINE_EMBED_DIMENSIONS,
  FULL_APP_DIMENSIONS,
  SKELETON_VARIANT_EMBED,
} from '~/observability/constants';

import { darkModeEnabled } from '~/lib/utils/color_utils';

jest.mock('~/lib/utils/color_utils');

describe('ObservabilityApp', () => {
  let wrapper;

  const $route = {
    pathname: 'https://gitlab.com/gitlab-org/',
    path: 'https://gitlab.com/gitlab-org/-/observability/dashboards',
    query: { otherQuery: 100 },
  };

  const mockHandleSkeleton = jest.fn();

  const findIframe = () => wrapper.findByTestId('observability-ui-iframe');

  const TEST_IFRAME_SRC = 'https://observe.gitlab.com/9970/?groupId=14485840';

  const TEST_USERNAME = 'test-user';

  const mountComponent = (props) => {
    wrapper = shallowMountExtended(ObservabilityApp, {
      propsData: {
        observabilityIframeSrc: TEST_IFRAME_SRC,
        ...props,
      },
      stubs: {
        'observability-skeleton': ObservabilitySkeleton,
      },
      mocks: {
        $route,
      },
    });
  };

  const dispatchMessageEvent = (message) =>
    window.dispatchEvent(new MessageEvent('message', message));

  beforeEach(() => {
    gon.current_username = TEST_USERNAME;
  });

  describe('iframe src', () => {
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

  describe('iframe kiosk query param', () => {
    it('when inlineEmbed, it should set the proper kiosk query parameter', () => {
      mountComponent({
        inlineEmbed: true,
      });

      const iframe = findIframe();

      expect(iframe.attributes('src')).toBe(
        `${TEST_IFRAME_SRC}&theme=light&username=${TEST_USERNAME}&kiosk=inline-embed`,
      );
    });
  });

  describe('iframe size', () => {
    it('should set the specified size', () => {
      mountComponent({
        height: INLINE_EMBED_DIMENSIONS.HEIGHT,
        width: INLINE_EMBED_DIMENSIONS.WIDTH,
      });

      const iframe = findIframe();

      expect(iframe.attributes('width')).toBe(INLINE_EMBED_DIMENSIONS.WIDTH);
      expect(iframe.attributes('height')).toBe(INLINE_EMBED_DIMENSIONS.HEIGHT);
    });

    it('should fallback to default size', () => {
      mountComponent({});

      const iframe = findIframe();

      expect(iframe.attributes('width')).toBe(FULL_APP_DIMENSIONS.WIDTH);
      expect(iframe.attributes('height')).toBe(FULL_APP_DIMENSIONS.HEIGHT);
    });
  });

  describe('skeleton variant', () => {
    it('sets the specified skeleton variant', () => {
      mountComponent({ skeletonVariant: SKELETON_VARIANT_EMBED });
      const props = wrapper.findComponent(ObservabilitySkeleton).props();

      expect(props.variant).toBe(SKELETON_VARIANT_EMBED);
    });

    it('should have a default skeleton variant', () => {
      mountComponent();
      const props = wrapper.findComponent(ObservabilitySkeleton).props();

      expect(props.variant).toBe('dashboards');
    });
  });

  describe('on GOUI_ROUTE_UPDATE', () => {
    it('should emit a route-update event', () => {
      mountComponent();

      const payload = { url: '/explore' };
      dispatchMessageEvent({
        data: { type: MESSAGE_EVENT_TYPE.GOUI_ROUTE_UPDATE, payload },
        origin: 'https://observe.gitlab.com',
      });

      expect(wrapper.emitted('route-update')[0]).toEqual([payload]);
    });
  });

  describe('on GOUI_LOADED', () => {
    beforeEach(() => {
      mountComponent();
      wrapper.vm.$refs.observabilitySkeleton.onContentLoaded = mockHandleSkeleton;
    });
    it('should call onContentLoaded method', () => {
      dispatchMessageEvent({
        data: { type: MESSAGE_EVENT_TYPE.GOUI_LOADED },
        origin: 'https://observe.gitlab.com',
      });
      expect(mockHandleSkeleton).toHaveBeenCalled();
    });

    it('should not call onContentLoaded method if origin is different', () => {
      dispatchMessageEvent({
        data: { type: MESSAGE_EVENT_TYPE.GOUI_LOADED },
        origin: 'https://example.com',
      });
      expect(mockHandleSkeleton).not.toHaveBeenCalled();
    });

    it('should not call onContentLoaded method if event type is different', () => {
      dispatchMessageEvent({
        data: { type: 'UNKNOWN_EVENT' },
        origin: 'https://observe.gitlab.com',
      });
      expect(mockHandleSkeleton).not.toHaveBeenCalled();
    });
  });

  describe('on unmount', () => {
    it('should not emit any even on route update', () => {
      mountComponent();
      wrapper.destroy();

      dispatchMessageEvent({
        data: { type: MESSAGE_EVENT_TYPE.GOUI_ROUTE_UPDATE, payload: { url: '/explore' } },
        origin: 'https://observe.gitlab.com',
      });

      expect(wrapper.emitted('route-update')).toBeUndefined();
    });
  });
});

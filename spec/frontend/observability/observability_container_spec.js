import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import ObservabilityContainer from '~/observability/components/observability_container.vue';
import ObservabilitySkeleton from '~/observability/components/skeleton/index.vue';
import { buildClient } from '~/observability/client';

jest.mock('~/observability/client');

describe('ObservabilityContainer', () => {
  let wrapper;

  const mockSkeletonOnContentLoaded = jest.fn();
  const mockSkeletonOnError = jest.fn();

  const OAUTH_URL = 'https://example.com/oauth';
  const TRACING_URL = 'https://example.com/tracing';
  const PROVISIONING_URL = 'https://example.com/provisioning';

  beforeEach(() => {
    jest.spyOn(console, 'error').mockImplementation();

    buildClient.mockReturnValue({});

    wrapper = shallowMountExtended(ObservabilityContainer, {
      propsData: {
        oauthUrl: OAUTH_URL,
        tracingUrl: TRACING_URL,
        provisioningUrl: PROVISIONING_URL,
      },
      stubs: {
        ObservabilitySkeleton: stubComponent(ObservabilitySkeleton, {
          methods: { onContentLoaded: mockSkeletonOnContentLoaded, onError: mockSkeletonOnError },
        }),
      },
      slots: {
        default: {
          render(h) {
            h(`<div>mockedComponent</div>`);
          },
          name: 'MockComponent',
          props: {
            observabilityClient: {
              type: Object,
              required: true,
            },
          },
        },
      },
    });
  });

  const dispatchMessageEvent = (status, origin) =>
    window.dispatchEvent(
      new MessageEvent('message', {
        data: {
          type: 'AUTH_COMPLETION',
          status,
        },
        origin: origin ?? new URL(OAUTH_URL).origin,
      }),
    );

  const findIframe = () => wrapper.findByTestId('observability-oauth-iframe');
  const findSlotComponent = () => wrapper.findComponent({ name: 'MockComponent' });

  it('should render the oauth iframe', () => {
    const iframe = findIframe();
    expect(iframe.exists()).toBe(true);
    expect(iframe.attributes('hidden')).toBe('hidden');
    expect(iframe.attributes('src')).toBe(OAUTH_URL);
    expect(iframe.attributes('sandbox')).toBe('allow-same-origin allow-forms allow-scripts');
  });

  it('should render the ObservabilitySkeleton', () => {
    const skeleton = wrapper.findComponent(ObservabilitySkeleton);
    expect(skeleton.exists()).toBe(true);
  });

  it('should not render the default slot', () => {
    expect(findSlotComponent().exists()).toBe(false);
  });

  it('renders the slot content and removes the iframe on oauth success message', async () => {
    dispatchMessageEvent('success');

    await nextTick();

    expect(mockSkeletonOnContentLoaded).toHaveBeenCalledTimes(1);

    const slotComponent = findSlotComponent();
    expect(slotComponent.exists()).toBe(true);
    expect(buildClient).toHaveBeenCalledWith({
      provisioningUrl: PROVISIONING_URL,
      tracingUrl: TRACING_URL,
    });
    expect(findIframe().exists()).toBe(false);
  });

  it('does not render the slot content and removes the iframe on oauth error message', async () => {
    dispatchMessageEvent('error');

    await nextTick();

    expect(mockSkeletonOnError).toHaveBeenCalledTimes(1);

    expect(findSlotComponent().exists()).toBe(false);
    expect(findIframe().exists()).toBe(false);
    expect(buildClient).not.toHaveBeenCalled();
  });

  it('handles oauth message only once', () => {
    dispatchMessageEvent('success');
    dispatchMessageEvent('success');

    expect(mockSkeletonOnContentLoaded).toHaveBeenCalledTimes(1);
  });

  it('only handles messages from the oauth url', () => {
    dispatchMessageEvent('success', 'www.fake-url.com');

    expect(mockSkeletonOnContentLoaded).toHaveBeenCalledTimes(0);
    expect(findSlotComponent().exists()).toBe(false);
    expect(findIframe().exists()).toBe(true);
  });

  it('does not handle messages if the component has been destroyed', () => {
    wrapper.destroy();

    dispatchMessageEvent('success');

    expect(mockSkeletonOnContentLoaded).toHaveBeenCalledTimes(0);
  });
});

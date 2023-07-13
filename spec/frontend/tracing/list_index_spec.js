import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListIndex from '~/tracing/list_index.vue';
import TracingList from '~/tracing/components/tracing_list.vue';
import ObservabilityContainer from '~/observability/components/observability_container.vue';

describe('ListIndex', () => {
  const props = {
    oauthUrl: 'https://example.com/oauth',
    tracingUrl: 'https://example.com/tracing',
    provisioningUrl: 'https://example.com/provisioning',
  };

  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMountExtended(ListIndex, {
      propsData: props,
    });
  };

  it('renders ObservabilityContainer component', () => {
    mountComponent();

    const observabilityContainer = wrapper.findComponent(ObservabilityContainer);
    expect(observabilityContainer.exists()).toBe(true);
    expect(observabilityContainer.props('oauthUrl')).toBe(props.oauthUrl);
    expect(observabilityContainer.props('tracingUrl')).toBe(props.tracingUrl);
    expect(observabilityContainer.props('provisioningUrl')).toBe(props.provisioningUrl);
  });

  it('renders TracingList component inside ObservabilityContainer', () => {
    mountComponent();

    const observabilityContainer = wrapper.findComponent(ObservabilityContainer);
    expect(observabilityContainer.findComponent(TracingList).exists()).toBe(true);
  });
});

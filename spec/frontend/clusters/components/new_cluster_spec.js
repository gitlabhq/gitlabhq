import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import NewCluster from '~/clusters/components/new_cluster.vue';
import createClusterStore from '~/clusters/stores/new_cluster';

describe('NewCluster', () => {
  let store;
  let wrapper;

  const createWrapper = () => {
    store = createClusterStore({ clusterConnectHelpPath: '/some/help/path' });
    wrapper = shallowMount(NewCluster, { store, stubs: { GlLink, GlSprintf } });
    return wrapper.vm.$nextTick();
  };

  const findDescription = () => wrapper.find(GlSprintf);

  const findLink = () => wrapper.find(GlLink);

  beforeEach(() => {
    return createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the cluster component correctly', () => {
    expect(wrapper.html()).toMatchSnapshot();
  });

  it('renders the correct information text', () => {
    expect(findDescription().text()).toContain(
      'Please enter access information for your Kubernetes cluster.',
    );
  });

  it('renders a valid help link set by the backend', () => {
    expect(findLink().attributes('href')).toBe('/some/help/path');
  });
});

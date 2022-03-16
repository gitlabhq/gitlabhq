import { GlEmptyState, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ClustersEmptyState from '~/clusters_list/components/clusters_empty_state.vue';
import ClusterStore from '~/clusters_list/store';

const clustersEmptyStateImage = 'path/to/svg';
const addClusterPath = '/path/to/connect/cluster';
const emptyStateHelpText = 'empty state text';

describe('ClustersEmptyStateComponent', () => {
  let wrapper;

  const defaultProvideData = {
    clustersEmptyStateImage,
    addClusterPath,
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findEmptyStateText = () => wrapper.findByTestId('clusters-empty-state-text');

  const createWrapper = ({
    provideData = { emptyStateHelpText: null },
    isChildComponent = false,
    canAddCluster = true,
  } = {}) => {
    wrapper = shallowMountExtended(ClustersEmptyState, {
      store: ClusterStore({ canAddCluster }),
      propsData: { isChildComponent },
      provide: { ...defaultProvideData, ...provideData },
      stubs: { GlEmptyState },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when the component is loaded independently', () => {
    it('should render the action button', () => {
      expect(findButton().exists()).toBe(true);
    });
  });

  describe('when the help text is not provided', () => {
    it('should not render the empty state text', () => {
      expect(findEmptyStateText().exists()).toBe(false);
    });
  });

  describe('when the component is loaded as a child component', () => {
    beforeEach(() => {
      createWrapper({ isChildComponent: true });
    });

    it('should not render the action button', () => {
      expect(findButton().exists()).toBe(false);
    });
  });

  describe('when the help text is provided', () => {
    beforeEach(() => {
      createWrapper({ provideData: { emptyStateHelpText } });
    });

    it('should show the empty state text', () => {
      expect(findEmptyStateText().text()).toBe(emptyStateHelpText);
    });
  });

  describe('when the user cannot add clusters', () => {
    beforeEach(() => {
      createWrapper({ canAddCluster: false });
    });
    it('should disable the button', () => {
      expect(findButton().props('disabled')).toBe(true);
    });
  });
});

import { GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ClustersEmptyState from '~/clusters_list/components/clusters_empty_state.vue';

const clustersEmptyStateImage = 'path/to/svg';
const emptyStateHelpText = 'empty state text';

describe('ClustersEmptyStateComponent', () => {
  let wrapper;

  const defaultProvideData = {
    clustersEmptyStateImage,
  };

  const findEmptyStateText = () => wrapper.findByTestId('clusters-empty-state-text');

  const createWrapper = ({ provideData = { emptyStateHelpText: null } } = {}) => {
    wrapper = shallowMountExtended(ClustersEmptyState, {
      provide: { ...defaultProvideData, ...provideData },
      stubs: { GlEmptyState },
    });
  };

  describe('when the help text is not provided', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should not render the empty state text', () => {
      expect(findEmptyStateText().exists()).toBe(false);
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
});

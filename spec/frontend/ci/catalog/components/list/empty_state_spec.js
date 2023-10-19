import { GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EmptyState from '~/ci/catalog/components/list/empty_state.vue';

describe('EmptyState', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(EmptyState, {
      propsData: {
        ...props,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
  });
});

import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ResultsError from '~/search/results/components/result_error.vue';

describe('when resultsError', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ResultsError, {
      stubs: {
        GlEmptyState,
        GlSprintf,
        GlLink,
      },
    });
  };

  describe('when component loads normally', () => {
    beforeEach(() => {
      createComponent();
    });

    it(`renders component properly`, () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});

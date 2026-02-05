import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ResultsError from '~/search/results/components/result_error.vue';
import { ZOEKT_CONNECTION_ERROR_IDENTIFIER } from '~/search/results/constants';

describe('when resultsError', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ResultsError, {
      propsData: props,
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

  describe('when error is a default error', () => {
    beforeEach(() => {
      const error = {
        graphQLErrors: [
          {
            message: 'search error: invalid query',
            extensions: {
              error_type: 'Search::Zoekt::Errors::BaseError',
            },
          },
        ],
      };
      createComponent({ error });
    });

    it('sets errorType to default', () => {
      expect(wrapper.vm.errorType).toBe('default');
    });

    it('shows default error title', () => {
      expect(wrapper.vm.errorTitle).toBe('A problem has occurred');
    });

    it('shows default error description', () => {
      expect(wrapper.vm.errorDescription).toContain('check the query syntax');
    });

    it('shows syntax help link', () => {
      expect(wrapper.vm.showSyntaxLink).toBe(true);
    });
  });

  describe('when error is a network error', () => {
    beforeEach(() => {
      const error = {
        graphQLErrors: [
          {
            message: 'ClientConnectionError: failed to connect',
            extensions: {
              error_type: ZOEKT_CONNECTION_ERROR_IDENTIFIER,
            },
          },
        ],
      };
      createComponent({ error });
    });

    it('sets errorType to network', () => {
      expect(wrapper.vm.errorType).toBe('network');
    });

    it('shows default error title', () => {
      expect(wrapper.vm.errorTitle).toBe('A problem has occurred');
    });

    it('shows network error description', () => {
      expect(wrapper.vm.errorDescription).toContain('Cannot connect to the Zoekt');
    });

    it('does not show syntax help link', () => {
      expect(wrapper.vm.showSyntaxLink).toBe(false);
    });
  });
});

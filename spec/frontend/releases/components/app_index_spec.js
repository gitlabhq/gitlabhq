import { shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import Vue from 'vue';
import Vuex from 'vuex';
import { getParameterByName } from '~/lib/utils/url_utility';
import AppIndex from '~/releases/components/app_index.vue';
import ReleaseSkeletonLoader from '~/releases/components/release_skeleton_loader.vue';
import ReleasesPagination from '~/releases/components/releases_pagination.vue';
import ReleasesSort from '~/releases/components/releases_sort.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  getParameterByName: jest.fn(),
}));

Vue.use(Vuex);

describe('app_index.vue', () => {
  let wrapper;
  let fetchReleasesSpy;
  let urlParams;

  const createComponent = (storeUpdates) => {
    wrapper = shallowMount(AppIndex, {
      store: new Vuex.Store({
        modules: {
          index: merge(
            {
              namespaced: true,
              actions: {
                fetchReleases: fetchReleasesSpy,
              },
              state: {
                isLoading: true,
                releases: [],
              },
            },
            storeUpdates,
          ),
        },
      }),
    });
  };

  beforeEach(() => {
    fetchReleasesSpy = jest.fn();
    getParameterByName.mockImplementation((paramName) => urlParams[paramName]);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  // Finders
  const findLoadingIndicator = () => wrapper.find(ReleaseSkeletonLoader);
  const findEmptyState = () => wrapper.find('[data-testid="empty-state"]');
  const findSuccessState = () => wrapper.find('[data-testid="success-state"]');
  const findPagination = () => wrapper.find(ReleasesPagination);
  const findSortControls = () => wrapper.find(ReleasesSort);
  const findNewReleaseButton = () => wrapper.find('[data-testid="new-release-button"]');

  // Expectations
  const expectLoadingIndicator = (shouldExist) => {
    it(`${shouldExist ? 'renders' : 'does not render'} a loading indicator`, () => {
      expect(findLoadingIndicator().exists()).toBe(shouldExist);
    });
  };

  const expectEmptyState = (shouldExist) => {
    it(`${shouldExist ? 'renders' : 'does not render'} an empty state`, () => {
      expect(findEmptyState().exists()).toBe(shouldExist);
    });
  };

  const expectSuccessState = (shouldExist) => {
    it(`${shouldExist ? 'renders' : 'does not render'} the success state`, () => {
      expect(findSuccessState().exists()).toBe(shouldExist);
    });
  };

  const expectPagination = (shouldExist) => {
    it(`${shouldExist ? 'renders' : 'does not render'} the pagination controls`, () => {
      expect(findPagination().exists()).toBe(shouldExist);
    });
  };

  const expectNewReleaseButton = (shouldExist) => {
    it(`${shouldExist ? 'renders' : 'does not render'} the "New release" button`, () => {
      expect(findNewReleaseButton().exists()).toBe(shouldExist);
    });
  };

  // Tests
  describe('on startup', () => {
    it.each`
      before                  | after
      ${null}                 | ${null}
      ${'before_param_value'} | ${null}
      ${null}                 | ${'after_param_value'}
    `(
      'calls fetchRelease with the correct parameters based on the curent query parameters: before: $before, after: $after',
      ({ before, after }) => {
        urlParams = { before, after };

        createComponent();

        expect(fetchReleasesSpy).toHaveBeenCalledTimes(1);
        expect(fetchReleasesSpy).toHaveBeenCalledWith(expect.anything(), urlParams);
      },
    );
  });

  describe('when the request to fetch releases has not yet completed', () => {
    beforeEach(() => {
      createComponent();
    });

    expectLoadingIndicator(true);
    expectEmptyState(false);
    expectSuccessState(false);
    expectPagination(false);
  });

  describe('when the request fails', () => {
    beforeEach(() => {
      createComponent({
        state: {
          isLoading: false,
          hasError: true,
        },
      });
    });

    expectLoadingIndicator(false);
    expectEmptyState(false);
    expectSuccessState(false);
    expectPagination(true);
  });

  describe('when the request succeeds but returns no releases', () => {
    beforeEach(() => {
      createComponent({
        state: {
          isLoading: false,
        },
      });
    });

    expectLoadingIndicator(false);
    expectEmptyState(true);
    expectSuccessState(false);
    expectPagination(true);
  });

  describe('when the request succeeds and includes at least one release', () => {
    beforeEach(() => {
      createComponent({
        state: {
          isLoading: false,
          releases: [{}],
        },
      });
    });

    expectLoadingIndicator(false);
    expectEmptyState(false);
    expectSuccessState(true);
    expectPagination(true);
  });

  describe('sorting', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the sort controls', () => {
      expect(findSortControls().exists()).toBe(true);
    });

    it('calls the fetchReleases store method when the sort is updated', () => {
      fetchReleasesSpy.mockClear();

      findSortControls().vm.$emit('sort:changed');

      expect(fetchReleasesSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe('"New release" button', () => {
    describe('when the user is allowed to create releases', () => {
      const newReleasePath = 'path/to/new/release/page';

      beforeEach(() => {
        createComponent({ state: { newReleasePath } });
      });

      expectNewReleaseButton(true);

      it('renders the button with the correct href', () => {
        expect(findNewReleaseButton().attributes('href')).toBe(newReleasePath);
      });
    });

    describe('when the user is not allowed to create releases', () => {
      beforeEach(() => {
        createComponent();
      });

      expectNewReleaseButton(false);
    });
  });

  describe("when the browser's back button is pressed", () => {
    beforeEach(() => {
      urlParams = {
        before: 'before_param_value',
      };

      createComponent();

      fetchReleasesSpy.mockClear();

      window.dispatchEvent(new PopStateEvent('popstate'));
    });

    it('calls the fetchRelease store method with the parameters from the URL query', () => {
      expect(fetchReleasesSpy).toHaveBeenCalledTimes(1);
      expect(fetchReleasesSpy).toHaveBeenCalledWith(expect.anything(), urlParams);
    });
  });
});

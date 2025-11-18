import {
  GlModal,
  GlSearchBoxByType,
  GlFormCheckboxGroup,
  GlFormCheckbox,
  GlEmptyState,
} from '@gitlab/ui';
import { nextTick } from 'vue';
import axios from '~/lib/utils/axios_utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RefTrackingSelection from '~/security_configuration/components/ref_tracking_selection.vue';
import RefTrackingSelectionSummary from '~/security_configuration/components/ref_tracking_selection_summary.vue';
import * as refsApi from '~/security_configuration/security_attributes/api/refs_api';
import { createTrackedRef } from '../mock_data';

const mockRefs = [
  {
    id: 'branch-main',
    name: 'main',
    refType: 'BRANCH',
  },
  {
    id: 'branch-feature-branch',
    name: 'feature-branch',
    refType: 'BRANCH',
  },
  {
    id: 'tag-v1.0.0',
    name: 'v1.0.0',
    refType: 'TAG',
  },
];

describe('RefTrackingSelection component', () => {
  let wrapper;
  let fetchRefsSpy;
  let fetchMostRecentlyUpdatedSpy;

  const createComponent = ({
    apiHandler = null,
    mostRecentlyUpdatedHandler = null,
    trackedRefs = [],
    maxTrackedRefs = 3,
  } = {}) => {
    const defaultHandler = jest.fn().mockResolvedValue(mockRefs);
    const searchHandler = apiHandler || defaultHandler;
    const mostRecentHandler = mostRecentlyUpdatedHandler || defaultHandler;

    fetchRefsSpy = jest.spyOn(refsApi, 'fetchRefs').mockImplementation(searchHandler);
    fetchMostRecentlyUpdatedSpy = jest
      .spyOn(refsApi, 'fetchMostRecentlyUpdated')
      .mockImplementation(mostRecentHandler);

    wrapper = shallowMountExtended(RefTrackingSelection, {
      provide: {
        projectFullPath: 'gitlab-org/gitlab',
      },
      propsData: {
        trackedRefs,
        maxTrackedRefs,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findSelectionSummary = () => wrapper.findComponent(RefTrackingSelectionSummary);
  const findCheckboxGroup = () => wrapper.findComponent(GlFormCheckboxGroup);
  const findAllCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findErrorAlert = () => wrapper.findByTestId('fetch-error-alert');
  const findLoadingSkeleton = () => wrapper.findByTestId('loading-skeleton');
  const findSkeletonLoaders = () => findLoadingSkeleton().findAll('gl-skeleton-loader-stub');
  const findListHeader = () => wrapper.findByTestId('list-header');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const enterSearchTerm = async (searchTerm) => {
    findSearchBox().vm.$emit('input', searchTerm);
    await waitForPromises();
  };

  const clickRefs = async (refs) => {
    for (const ref of refs) {
      wrapper.findByTestId(`ref-list-item-${ref.id}`).trigger('click');
    }
    await nextTick();
  };

  const getSelectedRefs = () => {
    const checked = findCheckboxGroup().attributes('checked');
    return checked ? checked.split(',') : [];
  };

  const findCheckboxForRef = (ref) => {
    return findAllCheckboxes().wrappers.find((checkbox) => checkbox.props('value') === ref.id);
  };

  describe('modal rendering', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
      await nextTick();
    });

    it('renders a visible modal', () => {
      expect(findModal().props('visible')).toBe(true);
    });

    it('configures primary action correctly', () => {
      expect(findModal().props('actionPrimary')).toMatchObject({
        text: 'Track ref(s)',
        attributes: {
          variant: 'confirm',
          disabled: true,
        },
      });
    });

    it('configures the cancel action correctly', () => {
      expect(findModal().props('actionCancel')).toEqual({
        text: 'Cancel',
      });
    });

    it('configures the modal with correct basic props', () => {
      expect(findModal().props()).toMatchObject({
        actionCancel: { text: 'Cancel' },
        modalId: 'track-ref-selection-modal',
        size: 'lg',
      });
    });

    it('renders the search box with a correct placeholder', () => {
      expect(findSearchBox().attributes('placeholder')).toBe(
        'Search branches and tags (enter at least 3 characters)',
      );
    });

    it('displays all refs after loading', () => {
      expect(findAllCheckboxes()).toHaveLength(mockRefs.length);
    });

    it('displays the correct header for the most-recently updated refs list', () => {
      expect(findListHeader().text()).toBe('Most recently updated');
    });
  });

  describe('REST API integration', () => {
    it('fetches the most recently updated refs when the component is created', async () => {
      createComponent();
      await waitForPromises();

      expect(fetchMostRecentlyUpdatedSpy).toHaveBeenCalledWith('gitlab-org/gitlab', { limit: 6 });
      expect(fetchRefsSpy).not.toHaveBeenCalled();
      expect(findAllCheckboxes()).toHaveLength(mockRefs.length);
    });

    it('limits the displayed refs to "6" items', async () => {
      const manyRefs = Array.from({ length: 10 }, (_, i) => ({
        id: `branch-ref-${i}`,
        name: `ref-${i}`,
        refType: 'BRANCH',
        isProtected: false,
        commit: {
          sha: `sha${i}abcdefghijklmnop`,
          shortId: `sha${i}abcd`,
          title: `Commit for ref-${i}`,
          authoredDate: '2024-11-01T12:00:00Z',
          webPath: `/project/-/commit/sha${i}abcd`,
        },
      }));

      createComponent({
        mostRecentlyUpdatedHandler: jest.fn().mockResolvedValue(manyRefs),
      });
      await waitForPromises();

      expect(findAllCheckboxes()).toHaveLength(6);
    });

    it('shows the loading state while fetching refs', () => {
      createComponent();

      expect(findLoadingSkeleton().exists()).toBe(true);
      expect(findSkeletonLoaders()).toHaveLength(5);
    });

    it('hides the loading state after data is loaded', async () => {
      createComponent();
      await waitForPromises();

      expect(findLoadingSkeleton().exists()).toBe(false);
      expect(findCheckboxGroup().exists()).toBe(true);
    });

    it('handles fetch errors', async () => {
      createComponent({
        mostRecentlyUpdatedHandler: jest.fn().mockRejectedValue(new Error('Fetch failed')),
      });
      await waitForPromises();

      expect(findErrorAlert().text()).toBe(
        'Could not fetch available refs. Please try again later.',
      );
    });
  });

  describe('selection functionality', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('allows refs to be selected', async () => {
      const refsToSelect = [mockRefs[0], mockRefs[1]];
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(true);

      await clickRefs(refsToSelect);

      expect(getSelectedRefs()).toEqual(refsToSelect.map((ref) => ref.id));
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(false);
    });
  });

  describe('selection summary', () => {
    const MAX_TRACKED_REFS = 3;

    beforeEach(async () => {
      createComponent({ maxTrackedRefs: MAX_TRACKED_REFS });
      await waitForPromises();
    });

    it('passes the selected refs to the summary component', async () => {
      await clickRefs([mockRefs[0], mockRefs[1]]);

      expect(findSelectionSummary().props('selectedRefs')).toEqual([mockRefs[0], mockRefs[1]]);
    });

    it('passes the available spots to the summary component', async () => {
      const selectedRefs = [mockRefs[0], mockRefs[1]];
      await clickRefs(selectedRefs);

      expect(findSelectionSummary().props('availableSpots')).toEqual(
        MAX_TRACKED_REFS - selectedRefs.length,
      );
    });

    it('handles the remove event from the summary component', async () => {
      await clickRefs([mockRefs[0], mockRefs[1]]);
      expect(getSelectedRefs()).toHaveLength(2);

      findSelectionSummary().vm.$emit('remove', mockRefs[0]);
      await nextTick();

      expect(getSelectedRefs()).toHaveLength(1);
      expect(getSelectedRefs()).toEqual([mockRefs[1].id]);
    });
  });

  describe('maximum tracked refs limit', () => {
    describe('without any refs that are already tracked', () => {
      beforeEach(async () => {
        createComponent({
          trackedRefs: [],
          maxTrackedRefs: 2,
        });
        await waitForPromises();
      });

      it('prevents selecting new refs when the max limit is reached', async () => {
        await clickRefs([mockRefs[0], mockRefs[1]]);
        expect(getSelectedRefs()).toHaveLength(2);

        expect(findCheckboxForRef(mockRefs[2]).props('disabled')).toBe(true);

        await clickRefs([mockRefs[2]]);

        expect(getSelectedRefs()).toHaveLength(2);
        expect(getSelectedRefs()).toEqual([mockRefs[0].id, mockRefs[1].id]);
      });

      it('allows deselecting refs when the max limit is reached', async () => {
        const selectedRefs = [mockRefs[0], mockRefs[1]];
        await clickRefs(selectedRefs);
        expect(getSelectedRefs()).toHaveLength(selectedRefs.length);

        selectedRefs.forEach((ref) => {
          expect(findCheckboxForRef(ref).props('disabled')).toBe(false);
        });

        await clickRefs([selectedRefs[0]]);

        expect(getSelectedRefs()).toHaveLength(selectedRefs.length - 1);
        expect(getSelectedRefs()).toEqual(selectedRefs.slice(1).map((ref) => ref.id));
      });
    });

    describe('with some refs that are already tracked', () => {
      beforeEach(async () => {
        createComponent({
          trackedRefs: [mockRefs[0]],
          maxTrackedRefs: 2,
        });
        await waitForPromises();
      });

      it('takes the tracked refs into account when checking if the max limit is reached', async () => {
        expect(findCheckboxForRef(mockRefs[2]).props('disabled')).toBe(false);

        await clickRefs([mockRefs[1], mockRefs[2]]);
        await nextTick();

        expect(findCheckboxForRef(mockRefs[2]).props('disabled')).toBe(true);

        expect(getSelectedRefs()).toHaveLength(1);
        expect(getSelectedRefs()).toEqual([mockRefs[1].id]);
      });
    });
  });

  describe('search functionality', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('displays the search-specific header', async () => {
      const searchTerm = 'main';

      await enterSearchTerm(searchTerm);

      expect(findListHeader().text()).toBe(`Search results for "${searchTerm}"`);
    });

    it('requires a minimum of "3" characters for the search to be triggered', async () => {
      await enterSearchTerm('ma');

      expect(fetchRefsSpy).not.toHaveBeenCalled();
      expect(fetchMostRecentlyUpdatedSpy).toHaveBeenCalledTimes(1);
    });

    it('triggers a search when more than "3" characters are entered', async () => {
      await enterSearchTerm('main');

      expect(fetchRefsSpy).toHaveBeenCalledWith(
        'gitlab-org/gitlab',
        {
          search: 'main',
          limit: 6,
        },
        expect.objectContaining({
          aborted: expect.any(Boolean),
        }),
      );
      expect(fetchMostRecentlyUpdatedSpy).toHaveBeenCalledTimes(1); // Only initial fetch
    });

    it('displays the search results', async () => {
      const searchResults = [mockRefs[0]];
      fetchRefsSpy.mockResolvedValue(searchResults);

      await enterSearchTerm('main');

      expect(findAllCheckboxes()).toHaveLength(1);
    });

    it('shows the loading state while searching', async () => {
      enterSearchTerm('main');
      await nextTick();

      expect(findLoadingSkeleton().exists()).toBe(true);
    });

    it('handles search errors', async () => {
      await waitForPromises();

      fetchRefsSpy.mockRejectedValue(new Error('Search failed'));

      await enterSearchTerm('main');

      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().text()).toBe('Could not search refs. Please try again later.');
    });
  });

  describe('empty state', () => {
    it('shows the empty state when there are no refs on initial load', async () => {
      createComponent({
        mostRecentlyUpdatedHandler: jest.fn().mockResolvedValue([]),
      });
      await waitForPromises();
      await nextTick();

      expect(findListHeader().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(true);
    });

    it('shows the empty state when there are no refs after searching', async () => {
      createComponent({
        apiHandler: jest.fn().mockResolvedValue([]),
      });
      await waitForPromises();

      expect(findListHeader().exists()).toBe(true);
      expect(findEmptyState().exists()).toBe(false);

      await enterSearchTerm('main');

      expect(findListHeader().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(true);
    });
  });

  describe('modal closing', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('emits cancel event when modal is hidden', async () => {
      await findModal().vm.$emit('hidden');

      expect(wrapper.emitted('cancel')).toHaveLength(1);
    });
  });

  describe('filtering already tracked refs passed in by the parent component', () => {
    const untrackedRef = mockRefs[1];

    const trackedRefs = [
      createTrackedRef({
        name: mockRefs[0].name,
        refType: mockRefs[0].refType,
      }),
      createTrackedRef({
        name: mockRefs[2].name,
        refType: mockRefs[2].refType,
      }),
    ];

    beforeEach(async () => {
      createComponent({ trackedRefs });
      await waitForPromises();
    });

    it('filters out tracked refs from available refs list', () => {
      const displayedCheckboxes = findAllCheckboxes();

      expect(displayedCheckboxes).toHaveLength(1);
      expect(displayedCheckboxes.at(0).attributes('value')).toBe(untrackedRef.id);
    });

    it('filters out tracked refs from search results', async () => {
      await enterSearchTerm('main');

      const displayedCheckboxes = findAllCheckboxes();
      expect(displayedCheckboxes).toHaveLength(1);
      expect(displayedCheckboxes.at(0).attributes('value')).toBe(untrackedRef.id);
    });
  });

  describe('request cancellation', () => {
    let abortSpy;

    beforeEach(() => {
      abortSpy = jest.spyOn(AbortController.prototype, 'abort');
      createComponent();
    });

    const mockInFlightRequest = () => {
      let resolver;
      const promise = new Promise((resolve) => {
        resolver = resolve;
      });
      return { promise, resolve: resolver };
    };

    it('passes AbortSignal to fetchRefs', async () => {
      await enterSearchTerm('main');

      expect(fetchRefsSpy).toHaveBeenCalledWith(
        'gitlab-org/gitlab',
        { search: 'main', limit: 6 },
        expect.objectContaining({
          aborted: expect.any(Boolean),
        }),
      );
    });

    it.each`
      description                        | initialSearchTerm | subsequentSearchTerm
      ${'new search is initiated'}       | ${'main'}         | ${'testing'}
      ${'search term becomes too short'} | ${'main'}         | ${'te'}
    `(
      'aborts in-flight search when $description',
      async ({ initialSearchTerm, subsequentSearchTerm }) => {
        const { promise: searchPromise, resolve: resolveSearch } = mockInFlightRequest();
        fetchRefsSpy.mockReturnValueOnce(searchPromise);

        await enterSearchTerm(initialSearchTerm);
        expect(abortSpy).not.toHaveBeenCalled();

        await enterSearchTerm(subsequentSearchTerm);

        expect(abortSpy).toHaveBeenCalledTimes(1);

        resolveSearch(mockRefs);
      },
    );

    it('aborts in-flight search when the component is destroyed', async () => {
      const { promise: searchPromise, resolve: resolveSearch } = mockInFlightRequest();
      fetchRefsSpy.mockReturnValueOnce(searchPromise);

      await enterSearchTerm('main');
      expect(abortSpy).not.toHaveBeenCalled();

      wrapper.destroy();

      expect(abortSpy).toHaveBeenCalledTimes(1);

      resolveSearch(mockRefs);
    });

    it.each`
      description                    | isCancelled | shouldShowError
      ${'the error is canceled'}     | ${true}     | ${false}
      ${'the error is not canceled'} | ${false}    | ${true}
    `(
      'when $description, does display the error message: $shouldShowError',
      async ({ isCancelled, shouldShowError }) => {
        fetchRefsSpy.mockRejectedValueOnce(new Error());
        axios.isCancel = jest.fn().mockReturnValueOnce(isCancelled);

        await enterSearchTerm('main');

        expect(findErrorAlert().exists()).toBe(shouldShowError);
      },
    );
  });
});

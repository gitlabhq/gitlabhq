import {
  GlModal,
  GlSearchBoxByType,
  GlFormCheckboxGroup,
  GlFormCheckbox,
  GlEmptyState,
} from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RefTrackingSelection from '~/security_configuration/components/ref_tracking_selection.vue';
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
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
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

  const selectRefs = async (refIds) => {
    await findCheckboxGroup().vm.$emit('input', refIds);
  };

  const getSelectedRefs = () => {
    const checked = findCheckboxGroup().attributes('checked');
    return checked ? checked.split(',') : [];
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
        'Search branches and tags (min. 3 characters)',
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
      const refsToSelect = ['branch-main', 'branch-feature-branch'];
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(true);

      await selectRefs(refsToSelect);

      expect(getSelectedRefs()).toEqual(refsToSelect);
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(false);
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

      expect(fetchRefsSpy).toHaveBeenCalledWith('gitlab-org/gitlab', {
        search: 'main',
        limit: 6,
      });
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
});

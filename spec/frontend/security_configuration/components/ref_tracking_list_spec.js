import {
  GlAlert,
  GlBadge,
  GlButton,
  GlCard,
  GlSkeletonLoader,
  GlKeysetPagination,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RefTrackingList, {
  MAX_TRACKED_REFS,
} from '~/security_configuration/components/ref_tracking_list.vue';
import RefTrackingListItem from '~/security_configuration/components/ref_tracking_list_item.vue';
import RefUntrackingConfirmation from '~/security_configuration/components/ref_untracking_confirmation.vue';
import RefTrackingSelection from '~/security_configuration/components/ref_tracking_selection.vue';
import securityTrackedRefsQuery from '~/security_configuration/graphql/security_tracked_refs.query.graphql';
import { createTrackedRef, createMockTrackedRefsResponse } from '../mock_data';

Vue.use(VueApollo);

const mockTrackedRefs = [
  createTrackedRef({
    id: 'gid://gitlab/TrackedRef/1',
    name: 'Main',
    refType: 'HEAD',
    isDefault: true,
    isProtected: true,
    vulnerabilitiesCount: 258,
    commit: {
      sha: 'df210850abc123',
      shortId: 'df21085',
      title: 'Apply 1 suggestion(s) to 1 file(s)',
      authoredDate: '2024-10-17T09:59:00Z',
      webPath: '/project/-/commit/df21085',
    },
  }),
  createTrackedRef({
    id: 'gid://gitlab/TrackedRef/2',
    name: 'v18.1.4-33',
    refType: 'TAG',
    commit: {
      sha: '693bb5e6abc456',
      shortId: '693bb5e6',
      title: 'Update VERSION files',
      authoredDate: '2024-10-15T14:30:00Z',
      webPath: '/project/-/commit/693bb5e6',
    },
  }),
];

const mockTrackedRefsResponse = createMockTrackedRefsResponse({
  nodes: mockTrackedRefs,
});

describe('RefTrackingList component', () => {
  let wrapper;

  const createApolloProvider = ({
    queryHandler = jest.fn().mockResolvedValue(mockTrackedRefsResponse),
  } = {}) => createMockApollo([[securityTrackedRefsQuery, queryHandler]]);

  const createComponent = ({ queryHandler } = {}) => {
    wrapper = shallowMountExtended(RefTrackingList, {
      apolloProvider: createApolloProvider({ queryHandler }),
      provide: {
        projectFullPath: 'namespace/project',
      },
      stubs: {
        GlCard,
      },
    });
  };

  const findCard = () => wrapper.findComponent(GlCard);
  const findTitle = () => wrapper.findByTestId('tracked-refs-title');
  const findCountBadge = () => wrapper.findByTestId('tracked-refs-header').findComponent(GlBadge);
  const findTrackNewRefButton = () =>
    wrapper.findByTestId('tracked-refs-header').findComponent(GlButton);
  const findRefList = () => wrapper.find('ul[data-testid="tracked-refs-list"]');
  const findRefListItems = () => wrapper.findAllComponents(RefTrackingListItem);
  const findSkeletonLoaders = () => wrapper.findAllComponents(GlSkeletonLoader);
  const findErrorAlert = () => wrapper.findComponent(GlAlert);
  const findUntrackConfirmation = () => wrapper.findComponent(RefUntrackingConfirmation);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findTrackingSelection = () => wrapper.findComponent(RefTrackingSelection);

  const triggerUntrackRefItem = async (refToUntrack) => {
    findRefListItems().at(0).vm.$emit('untrack', refToUntrack);
    await nextTick();
  };

  describe('rendering', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders a GlCard', () => {
      expect(findCard().exists()).toBe(true);
    });

    it('renders header with title', () => {
      expect(findTitle().text()).toBe('Currently tracked refs');
    });

    it('renders count badge with current and max values', () => {
      expect(findCountBadge().text()).toBe(
        `${mockTrackedRefsResponse.data.project.securityTrackedRefs.count}/${MAX_TRACKED_REFS}`,
      );
    });

    it('renders Track new ref button', () => {
      expect(findTrackNewRefButton().text()).toBe('Track new ref(s)');
    });

    it('renders unordered list for refs', () => {
      expect(findRefList().exists()).toBe(true);
    });
  });

  describe('ref list items', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders correct number of RefTrackingListItem components', () => {
      expect(findRefListItems()).toHaveLength(mockTrackedRefs.length);
    });

    it.each(mockTrackedRefs)(
      'passes correct data to RefTrackingListItem for ref "$name"',
      (trackedRef) => {
        const index = mockTrackedRefs.indexOf(trackedRef);

        expect(findRefListItems().at(index).props('trackedRef')).toEqual(trackedRef);
      },
    );
  });

  describe('data querying', () => {
    const queryHandler = jest.fn().mockResolvedValue(mockTrackedRefsResponse);

    beforeEach(async () => {
      createComponent({ queryHandler });
      await waitForPromises();
    });

    it('queries the correct data when the component is created', () => {
      expect(queryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          first: MAX_TRACKED_REFS,
          fullPath: 'namespace/project',
        }),
      );
    });
  });

  describe('loading state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a placeholder within the count badge while loading', () => {
      expect(findCountBadge().text()).toBe(`-/${MAX_TRACKED_REFS}`);
    });

    it('shows skeleton loader while loading', () => {
      expect(findSkeletonLoaders()).toHaveLength(4);
      expect(findRefList().exists()).toBe(false);
    });

    it('hides skeleton loader after data loads', async () => {
      await waitForPromises();

      expect(findSkeletonLoaders()).toHaveLength(0);
      expect(findRefList().exists()).toBe(true);
      expect(findRefListItems()).toHaveLength(mockTrackedRefs.length);
    });
  });

  describe('error state', () => {
    beforeEach(async () => {
      createComponent({
        queryHandler: jest.fn().mockRejectedValue(new Error('Failed to load tracked refs.')),
      });
      await waitForPromises();
    });

    it('shows an error alert with the correct message', () => {
      expect(findErrorAlert().text()).toBe(
        'Could not fetch tracked refs. Please refresh the page, or try again later.',
      );
    });

    it('shows the tracked refs count as "-"', () => {
      expect(findCountBadge().text()).toBe(`-/${MAX_TRACKED_REFS}`);
    });

    it('does not show the skeleton loaders', () => {
      expect(findSkeletonLoaders()).toHaveLength(0);
    });

    it('does not show the ref list', () => {
      expect(findRefList().exists()).toBe(false);
    });
  });

  describe('untrack functionality', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('passes the tracked ref to the untrack confirmation modal when a list item emits the "untrack" event', async () => {
      const refToUntrack = mockTrackedRefs[0];

      expect(findUntrackConfirmation().props('refToUntrack')).toBeNull();

      await triggerUntrackRefItem(refToUntrack);

      expect(findUntrackConfirmation().props('refToUntrack')).toEqual(refToUntrack);
    });

    it('calls the mutation with the correct variables when the untrack confirmation modal emits the "confirm" event', async () => {
      const refToUntrack = mockTrackedRefs[0];
      // Note: Once we have the actual mutation available on the BE, we can move from using a spy to mocking the actual mutation.
      // Currently this would cause an error with mock-apollo
      const mutateSpy = jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
        data: {
          securityTrackedRefsUntrack: {
            success: true,
            untrackedRefIds: [refToUntrack.id],
          },
        },
      });

      await triggerUntrackRefItem(refToUntrack);

      expect(findUntrackConfirmation().props('refToUntrack')).toEqual(refToUntrack);

      findUntrackConfirmation().vm.$emit('confirm', {
        refId: refToUntrack.id,
        archiveVulnerabilities: false,
      });
      await waitForPromises();

      expect(mutateSpy).toHaveBeenCalled();
    });

    it('resets the tracked ref to `null` when the untrack confirmation modal emits the "cancel" event', async () => {
      const refToUntrack = mockTrackedRefs[0];

      await triggerUntrackRefItem(refToUntrack);

      expect(findUntrackConfirmation().props('refToUntrack')).toEqual(refToUntrack);

      findUntrackConfirmation().vm.$emit('cancel');
      await nextTick();

      expect(findUntrackConfirmation().props('refToUntrack')).toBeNull();
    });
  });

  describe('pagination', () => {
    it('does not show the pagination when there is no next page', async () => {
      createComponent({
        queryHandler: jest.fn().mockResolvedValue(
          createMockTrackedRefsResponse({
            nodes: mockTrackedRefs,
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
            },
          }),
        ),
      });
      await waitForPromises();

      expect(findPagination().exists()).toBe(false);
    });

    describe('when there are more pages', () => {
      const queryHandler = jest.fn().mockResolvedValue(
        createMockTrackedRefsResponse({
          nodes: mockTrackedRefs,
          hasNextPage: true,
          hasPreviousPage: true,
          startCursor: 'start-cursor',
          endCursor: 'end-cursor',
        }),
      );

      beforeEach(async () => {
        createComponent({ queryHandler });
        await waitForPromises();
      });

      it('shows the pagination', () => {
        expect(findPagination().exists()).toBe(true);
      });

      it('passes the correct props to the pagination', () => {
        expect(findPagination().props()).toMatchObject({
          hasNextPage: true,
          hasPreviousPage: true,
          startCursor: 'start-cursor',
          endCursor: 'end-cursor',
        });
      });

      it('queries the next page when the next page button is clicked', async () => {
        findPagination().vm.$emit('next');
        await waitForPromises();

        expect(queryHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            first: MAX_TRACKED_REFS,
            after: 'end-cursor',
            last: null,
            before: null,
          }),
        );
      });

      it('queries the previous page when the previous page button is clicked', async () => {
        findPagination().vm.$emit('prev');
        await waitForPromises();

        expect(queryHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            last: MAX_TRACKED_REFS,
            before: 'start-cursor',
            first: null,
            after: null,
          }),
        );
      });

      it.each(['next', 'prev'])(
        'shows the loading state when the %s page is requested',
        async (direction) => {
          findPagination().vm.$emit(direction);
          await nextTick();

          expect(findSkeletonLoaders()).toHaveLength(4);
        },
      );
    });
  });

  describe('track functionality', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('modal is initially hidden', () => {
      expect(findTrackingSelection().props('isVisible')).toBe(false);
    });

    it('opens the tracking selection modal when "Track new ref" button is clicked', async () => {
      expect(findTrackingSelection().props('isVisible')).toBe(false);

      findTrackNewRefButton().vm.$emit('click');
      await nextTick();

      expect(findTrackingSelection().props('isVisible')).toBe(true);
    });

    it('closes the tracking selection modal when the modal emits the "cancel" event', async () => {
      findTrackNewRefButton().vm.$emit('click');
      await nextTick();

      expect(findTrackingSelection().props('isVisible')).toBe(true);

      findTrackingSelection().vm.$emit('cancel');
      await nextTick();

      expect(findTrackingSelection().props('isVisible')).toBe(false);
    });
  });
});

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
import RefTrackingList from '~/security_configuration/components/ref_tracking_list.vue';
import RefTrackingListItem from '~/security_configuration/components/ref_tracking_list_item.vue';
import RefUntrackingConfirmation from '~/security_configuration/components/ref_untracking_confirmation.vue';
import RefTrackingSelection from '~/security_configuration/components/ref_tracking_selection.vue';
import securityTrackedRefsQuery from '~/security_configuration/graphql/security_tracked_refs.query.graphql';
import { createTrackedRef, createMockTrackedRefsResponse } from '../mock_data';

Vue.use(VueApollo);

const MAX_TRACKED_REFS = 3;

const mockTrackedRefs = [
  createTrackedRef({
    id: 'gid://gitlab/TrackedRef/1',
    name: 'Main',
    isDefault: true,
    vulnerabilitiesCount: 258,
  }),
  createTrackedRef({
    id: 'gid://gitlab/TrackedRef/2',
    name: 'v18.1.4-33',
    vulnerabilitiesCount: 100,
  }),
];

const mockTrackedRefsResponse = createMockTrackedRefsResponse({
  nodes: mockTrackedRefs,
});

const mockTrackedRefsResponseAtMaxLimit = createMockTrackedRefsResponse({
  nodes: mockTrackedRefs.concat([
    createTrackedRef({ id: 'gid://gitlab/TrackedRef/3', name: 'v1.0.0' }),
  ]),
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
  const getTrackNewRefButtonTooltip = () => {
    return wrapper.findByTestId('track-new-ref-button-tooltip').element.getAttribute('title');
  };
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

  const openTrackingModal = async () => {
    findTrackNewRefButton().vm.$emit('click');
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
      expect(findTrackingSelection().exists()).toBe(false);
    });

    it('opens the tracking selection modal when "Track new ref" button is clicked', async () => {
      expect(findTrackingSelection().exists()).toBe(false);

      await openTrackingModal();

      expect(findTrackingSelection().exists()).toBe(true);
    });

    it('closes the tracking selection modal when the modal emits the "cancel" event', async () => {
      await openTrackingModal();

      expect(findTrackingSelection().exists()).toBe(true);

      findTrackingSelection().vm.$emit('cancel');
      await nextTick();

      expect(findTrackingSelection().exists()).toBe(false);
    });

    it('passes tracked refs to the tracking selection modal', async () => {
      await openTrackingModal();

      expect(findTrackingSelection().props('trackedRefs')).toEqual(mockTrackedRefs);
    });

    it('passes max tracked refs to the tracking selection modal', async () => {
      await openTrackingModal();

      expect(findTrackingSelection().props('maxTrackedRefs')).toBe(MAX_TRACKED_REFS);
    });

    describe('track-new-ref-button disabled state', () => {
      it('is enabled when under max limit', async () => {
        createComponent({
          queryHandler: jest.fn().mockResolvedValue(mockTrackedRefsResponse),
        });
        await waitForPromises();

        expect(findTrackNewRefButton().attributes('disabled')).toBeUndefined();
      });

      it('is disabled when at max limit', async () => {
        createComponent({
          queryHandler: jest.fn().mockResolvedValue(mockTrackedRefsResponseAtMaxLimit),
        });
        await waitForPromises();

        expect(findTrackNewRefButton().attributes('disabled')).toBeDefined();
      });

      it('is disabled when loading', () => {
        createComponent();

        expect(findTrackNewRefButton().attributes('disabled')).toBeDefined();
      });
    });

    describe('track-new-ref-button tooltip', () => {
      it('shows loading tooltip when loading', () => {
        createComponent();

        expect(getTrackNewRefButtonTooltip()).toBe('Loading tracked refs. Please wait.');
      });

      it('shows tracking tooltip when tracking', async () => {
        createComponent();
        await waitForPromises();

        await openTrackingModal();
        findTrackingSelection().vm.$emit('select', [createTrackedRef()]);
        await nextTick();

        expect(getTrackNewRefButtonTooltip()).toBe('Tracking refs in progress. Please wait.');
      });

      it('shows max limit tooltip when at max limit', async () => {
        createComponent({
          queryHandler: jest.fn().mockResolvedValue(mockTrackedRefsResponseAtMaxLimit),
        });
        await waitForPromises();

        expect(getTrackNewRefButtonTooltip()).toBe(
          'Maximum number of tracked refs reached. Remove a ref to track a new one.',
        );
      });

      it('returns empty string when button is enabled', async () => {
        createComponent({
          queryHandler: jest.fn().mockResolvedValue(mockTrackedRefsResponse),
        });
        await waitForPromises();

        expect(getTrackNewRefButtonTooltip()).toBe('');
      });
    });

    describe('tracking refs', () => {
      const selectedRefs = [
        {
          name: 'develop',
          refType: 'HEAD',
          isProtected: false,
          commit: {
            sha: 'abc123',
            shortId: 'abc123',
            title: 'Test commit',
            authoredDate: '2024-11-01T10:00:00Z',
            webPath: '/project/-/commit/abc123',
          },
        },
      ];

      describe('success', () => {
        beforeEach(() => {
          jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
            data: {
              securityTrackedRefsTrack: {
                errors: [],
              },
            },
          });
        });

        it('closes the tracking modal when the modal emits the "select" event', async () => {
          await openTrackingModal();
          expect(findTrackingSelection().exists()).toBe(true);

          findTrackingSelection().vm.$emit('select', selectedRefs);
          await nextTick();

          expect(findTrackingSelection().exists()).toBe(false);
        });

        it('calls the mutation with the correct variables when refs are selected', async () => {
          const mutateSpy = jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
            data: {
              securityTrackedRefsTrack: {
                errors: [],
              },
            },
          });

          await openTrackingModal();

          findTrackingSelection().vm.$emit('select', selectedRefs);
          await waitForPromises();

          expect(mutateSpy).toHaveBeenCalledWith(
            expect.objectContaining({
              variables: {
                input: {
                  projectPath: 'namespace/project',
                  refs: [
                    {
                      name: 'develop',
                      refType: 'HEAD',
                      isProtected: false,
                      commit: {
                        sha: 'abc123',
                        shortId: 'abc123',
                        title: 'Test commit',
                        authoredDate: '2024-11-01T10:00:00Z',
                        webPath: '/project/-/commit/abc123',
                      },
                    },
                  ],
                },
              },
            }),
          );
        });

        it('shows loading state during tracking', async () => {
          await openTrackingModal();

          findTrackingSelection().vm.$emit('select', selectedRefs);
          await nextTick();

          expect(findSkeletonLoaders()).toHaveLength(4);
        });

        it('hides loading state after tracking completes', async () => {
          await openTrackingModal();

          findTrackingSelection().vm.$emit('select', selectedRefs);
          await waitForPromises();

          expect(findSkeletonLoaders()).toHaveLength(0);
        });

        it('refetches tracked refs query after successful mutation', async () => {
          // Note: Once we have the actual mutation available on the BE, we can move from using a spy to mocking the actual mutation.
          // Currently this would cause an error with mock-apollo
          const mutateSpy = jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
            data: {
              securityTrackedRefsTrack: {
                errors: [],
              },
            },
          });

          await openTrackingModal();

          findTrackingSelection().vm.$emit('select', selectedRefs);
          await waitForPromises();

          expect(mutateSpy).toHaveBeenCalledWith(
            expect.objectContaining({
              refetchQueries: [
                {
                  query: securityTrackedRefsQuery,
                  variables: { fullPath: 'namespace/project' },
                },
              ],
              awaitRefetchQueries: true,
            }),
          );
        });
      });

      describe('tracking refs errors', () => {
        let mutateSpy;

        beforeEach(async () => {
          mutateSpy = jest.spyOn(wrapper.vm.$apollo, 'mutate');
          createComponent();
          await waitForPromises();
        });

        describe('when mutation fails', () => {
          it.each`
            scenario                                 | mockImplementation
            ${'mutation throws an error'}            | ${() => mutateSpy.mockRejectedValue(new Error('Network error'))}
            ${'mutation returns errors in response'} | ${() => mutateSpy.mockResolvedValue({ data: { securityTrackedRefsTrack: { errors: ['Something went wrong'] } } })}
          `('shows dismissible error alert when $scenario', async ({ mockImplementation }) => {
            mockImplementation();

            await openTrackingModal();

            findTrackingSelection().vm.$emit('select', selectedRefs);
            await waitForPromises();

            expect(findErrorAlert().exists()).toBe(true);
            expect(findErrorAlert().text()).toBe(
              'Could not track refs. Please refresh the page, or try again later.',
            );

            findErrorAlert().vm.$emit('dismiss');
            await nextTick();

            expect(findErrorAlert().exists()).toBe(false);
          });
        });
      });
    });
  });
});

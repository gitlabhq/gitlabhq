import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DesignOverlay from '~/work_items/components/design_management/design_preview/design_overlay.vue';
import { resolvers } from '~/graphql_shared/issuable_client';
import activeDiscussionQuery from '~/work_items/components/design_management/graphql/client/active_design_discussion.query.graphql';
import notes from '../design_notes/mock_notes';

Vue.use(VueApollo);

describe('Design overlay component', () => {
  /** @type { import('helpers/vue_test_utils_helper').ExtendedWrapper } */
  let wrapper;
  let apolloProvider;

  const mockDimensions = { width: 100, height: 100 };

  const findOverlay = () => wrapper.findComponentByTestId('design-overlay');
  const findAllNotes = () => wrapper.findAllByTestId('note-pin');
  const findCommentBadge = () => wrapper.findByTestId('comment-badge');
  const findBadgeAtIndex = (noteIndex) => findAllNotes().at(noteIndex);
  const findFirstBadge = () => findBadgeAtIndex(0);
  const findSecondBadge = () => findBadgeAtIndex(1);

  const clickAndDragBadge = async (elem, fromPoint, toPoint) => {
    elem.vm.$emit(
      'mousedown',
      new MouseEvent('click', { clientX: fromPoint.x, clientY: fromPoint.y }),
    );
    await findOverlay().trigger('mousemove', { clientX: toPoint.x, clientY: toPoint.y });
    elem.vm.$emit('mouseup', new MouseEvent('click', { clientX: toPoint.x, clientY: toPoint.y }));
  };

  function createComponent(props = {}, data = {}) {
    apolloProvider = createMockApollo([], resolvers);
    apolloProvider.clients.defaultClient.writeQuery({
      query: activeDiscussionQuery,
      data: {
        activeDesignDiscussion: {
          __typename: 'ActiveDiscussion',
          id: null,
          source: null,
        },
      },
    });

    wrapper = shallowMountExtended(DesignOverlay, {
      apolloProvider,
      propsData: {
        dimensions: mockDimensions,
        position: {
          top: '0',
          left: '0',
        },
        resolvedDiscussionsExpanded: false,
        ...props,
      },
      data() {
        return {
          activeDesignDiscussion: {
            id: null,
            source: null,
          },
          ...data,
        };
      },
    });
  }

  afterEach(() => {
    apolloProvider = null;
  });

  it('should have correct inline style', () => {
    createComponent();

    expect(wrapper.attributes().style).toBe('width: 100px; height: 100px; top: 0px; left: 0px;');
  });

  it('should emit `openCommentForm` when clicking on overlay', () => {
    createComponent();
    const newCoordinates = {
      x: 10,
      y: 10,
    };

    wrapper
      .find('[data-testid="design-image-button"]')
      .trigger('mouseup', { offsetX: newCoordinates.x, offsetY: newCoordinates.y });

    expect(wrapper.emitted('openCommentForm')).toEqual([
      [{ x: newCoordinates.x, y: newCoordinates.y }],
    ]);
  });

  describe('with notes', () => {
    it('should render only the first note', () => {
      createComponent({
        notes,
      });
      expect(findAllNotes()).toHaveLength(1);
    });

    describe('with resolved discussions toggle expanded', () => {
      beforeEach(() => {
        createComponent({
          notes,
          resolvedDiscussionsExpanded: true,
        });
      });

      it('should render all notes', () => {
        expect(findAllNotes()).toHaveLength(notes.length);
      });

      it('should have set the correct position for each note badge', () => {
        expect(findFirstBadge().props('position')).toEqual({
          left: '10px',
          top: '15px',
        });
        expect(findSecondBadge().props('position')).toEqual({ left: '50px', top: '50px' });
      });

      it('should apply resolved class to the resolved note pin', () => {
        expect(findSecondBadge().props('isResolved')).toBe(true);
      });

      describe('when no discussion is active', () => {
        it('should not apply inactive class to any pins', () => {
          expect(
            findAllNotes(0).wrappers.every((designNote) => designNote.classes('gl-bg-blue-50')),
          ).toBe(false);
        });
      });

      describe('when a discussion is active', () => {
        it.each([notes[0].discussion.notes.nodes[1], notes[0].discussion.notes.nodes[0]])(
          'should not apply inactive class to the pin for the active discussion',
          async (note) => {
            apolloProvider.clients.defaultClient.writeQuery({
              query: activeDiscussionQuery,
              data: {
                activeDesignDiscussion: {
                  __typename: 'ActiveDiscussion',
                  id: note.id,
                  source: 'discussion',
                },
              },
            });

            await nextTick();
            await nextTick();

            expect(findBadgeAtIndex(0).props('isInactive')).toBe(false);
          },
        );

        it('should apply inactive class to all pins besides the active one', async () => {
          apolloProvider.clients.defaultClient.writeQuery({
            query: activeDiscussionQuery,
            data: {
              activeDesignDiscussion: {
                __typename: 'ActiveDiscussion',
                id: notes[0].id,
                source: 'discussion',
              },
            },
          });

          await nextTick();
          await nextTick();

          expect(findSecondBadge().props('isInactive')).toBe(true);
          expect(findFirstBadge().props('isInactive')).toBe(false);
        });
      });
    });

    it('should calculate badges positions based on dimensions', () => {
      createComponent({
        notes,
        dimensions: {
          width: 200,
          height: 200,
        },
      });

      expect(findFirstBadge().props('position')).toEqual({ left: '20px', top: '30px' });
    });

    it('should update active discussion when clicking a note without moving it', async () => {
      createComponent({
        notes,
        dimensions: {
          width: 400,
          height: 400,
        },
      });

      expect(findFirstBadge().props('isInactive')).toBe(null);

      const note = notes[0];
      const { position } = note;

      findFirstBadge().vm.$emit(
        'mousedown',
        new MouseEvent('click', { clientX: position.x, clientY: position.y }),
      );

      findFirstBadge().vm.$emit(
        'mouseup',
        new MouseEvent('click', { clientX: position.x, clientY: position.y }),
      );
      await waitForPromises();
      expect(findFirstBadge().props('isInactive')).toBe(false);
    });
  });

  describe('when moving notes', () => {
    it('should emit `moveNote` event when note-moving action ends', async () => {
      createComponent({ notes });
      const note = notes[0];
      const { position } = note;
      const newCoordinates = { x: 20, y: 20 };

      const badge = findFirstBadge();
      await clickAndDragBadge(badge, { x: position.x, y: position.y }, newCoordinates);

      expect(wrapper.emitted('moveNote')).toEqual([
        [
          {
            noteId: notes[0].id,
            discussionId: notes[0].discussion.id,
            coordinates: newCoordinates,
          },
        ],
      ]);
    });

    describe('without [repositionNote] permission', () => {
      const mockNoteNotAuthorised = {
        ...notes[0],
        userPermissions: {
          repositionNote: false,
        },
      };

      const mockNoteCoordinates = {
        x: mockNoteNotAuthorised.position.x,
        y: mockNoteNotAuthorised.position.y,
      };

      it('should be unable to move a note', async () => {
        createComponent({
          dimensions: mockDimensions,
          notes: [mockNoteNotAuthorised],
        });

        const badge = findAllNotes().at(0);
        await clickAndDragBadge(badge, { ...mockNoteCoordinates }, { x: 20, y: 20 });
        // note position should not change after a click-and-drag attempt
        expect(findFirstBadge().props('position')).toEqual({
          left: `${mockNoteCoordinates.x}px`,
          top: `${mockNoteCoordinates.y}px`,
        });
      });
    });
  });

  describe('with a new form', () => {
    it('should render a new comment badge', () => {
      createComponent({
        currentCommentForm: {
          ...notes[0].position,
        },
      });

      expect(findCommentBadge().exists()).toBe(true);
      expect(findCommentBadge().props('position')).toEqual({ left: '10px', top: '15px' });
    });

    describe('when moving the comment badge', () => {
      it('should update badge style when note-moving action ends', () => {
        const { position } = notes[0];
        createComponent({
          currentCommentForm: {
            ...position,
          },
        });

        expect(findCommentBadge().props('position')).toEqual({ left: '10px', top: '15px' });

        const toPoint = { x: 20, y: 20 };

        createComponent({
          currentCommentForm: { height: position.height, width: position.width, ...toPoint },
        });

        expect(findCommentBadge().props('position')).toEqual({ left: '20px', top: '20px' });
      });

      it('should emit `openCommentForm` event when mouseleave fired on overlay element', async () => {
        const { position } = notes[0];
        createComponent({
          notes,
          currentCommentForm: {
            ...position,
          },
        });

        const newCoordinates = { x: 20, y: 20 };

        await clickAndDragBadge(
          findCommentBadge(),
          { x: position.x, y: position.y },
          newCoordinates,
        );

        findOverlay().vm.$emit('mouseleave');
        expect(wrapper.emitted('openCommentForm')).toEqual([[newCoordinates]]);
      });

      it('should emit `openCommentForm` event when mouseup fired on comment badge element', async () => {
        const { position } = notes[0];
        createComponent({
          notes,
          currentCommentForm: {
            ...position,
          },
        });

        const newCoordinates = { x: 20, y: 20 };

        await clickAndDragBadge(
          findCommentBadge(),
          { x: position.x, y: position.y },
          newCoordinates,
        );

        expect(wrapper.emitted('openCommentForm')).toEqual([[newCoordinates]]);
      });
    });
  });

  describe('when notes are disabled', () => {
    it('does not render note pins', () => {
      createComponent({
        notes,
        disableNotes: true,
      });

      expect(findAllNotes()).toHaveLength(0);
    });
  });
});

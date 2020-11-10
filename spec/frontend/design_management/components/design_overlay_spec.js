import { mount } from '@vue/test-utils';
import DesignOverlay from '~/design_management/components/design_overlay.vue';
import updateActiveDiscussion from '~/design_management/graphql/mutations/update_active_discussion.mutation.graphql';
import notes from '../mock_data/notes';
import { ACTIVE_DISCUSSION_SOURCE_TYPES } from '~/design_management/constants';

const mutate = jest.fn(() => Promise.resolve());

describe('Design overlay component', () => {
  let wrapper;

  const mockDimensions = { width: 100, height: 100 };

  const findAllNotes = () => wrapper.findAll('.js-image-badge');
  const findCommentBadge = () => wrapper.find('.comment-indicator');
  const findBadgeAtIndex = noteIndex => findAllNotes().at(noteIndex);
  const findFirstBadge = () => findBadgeAtIndex(0);
  const findSecondBadge = () => findBadgeAtIndex(1);

  const clickAndDragBadge = (elem, fromPoint, toPoint) => {
    elem.trigger('mousedown', { clientX: fromPoint.x, clientY: fromPoint.y });
    return wrapper.vm.$nextTick().then(() => {
      elem.trigger('mousemove', { clientX: toPoint.x, clientY: toPoint.y });
      return wrapper.vm.$nextTick();
    });
  };

  function createComponent(props = {}, data = {}) {
    wrapper = mount(DesignOverlay, {
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
          activeDiscussion: {
            id: null,
            source: null,
          },
          ...data,
        };
      },
      mocks: {
        $apollo: {
          mutate,
        },
      },
    });
  }

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
      .find('[data-qa-selector="design_image_button"]')
      .trigger('mouseup', { offsetX: newCoordinates.x, offsetY: newCoordinates.y });
    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted('openCommentForm')).toEqual([
        [{ x: newCoordinates.x, y: newCoordinates.y }],
      ]);
    });
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
        expect(findFirstBadge().attributes().style).toBe('left: 10px; top: 15px;');
        expect(findSecondBadge().attributes().style).toBe('left: 50px; top: 50px;');
      });

      it('should apply resolved class to the resolved note pin', () => {
        expect(findSecondBadge().classes()).toContain('resolved');
      });

      describe('when no discussion is active', () => {
        it('should not apply inactive class to any pins', () => {
          expect(
            findAllNotes(0).wrappers.every(designNote => designNote.classes('gl-bg-blue-50')),
          ).toBe(false);
        });
      });

      describe('when a discussion is active', () => {
        it.each([notes[0].discussion.notes.nodes[1], notes[0].discussion.notes.nodes[0]])(
          'should not apply inactive class to the pin for the active discussion',
          note => {
            wrapper.setData({
              activeDiscussion: {
                id: note.id,
                source: 'discussion',
              },
            });

            return wrapper.vm.$nextTick().then(() => {
              expect(findBadgeAtIndex(0).classes()).not.toContain('inactive');
            });
          },
        );

        it('should apply inactive class to all pins besides the active one', () => {
          wrapper.setData({
            activeDiscussion: {
              id: notes[0].id,
              source: 'discussion',
            },
          });

          return wrapper.vm.$nextTick().then(() => {
            expect(findSecondBadge().classes()).toContain('inactive');
            expect(findFirstBadge().classes()).not.toContain('inactive');
          });
        });
      });
    });

    it('should recalculate badges positions on window resize', () => {
      createComponent({
        notes,
        dimensions: {
          width: 400,
          height: 400,
        },
      });

      expect(findFirstBadge().attributes().style).toBe('left: 40px; top: 60px;');

      wrapper.setProps({
        dimensions: {
          width: 200,
          height: 200,
        },
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(findFirstBadge().attributes().style).toBe('left: 20px; top: 30px;');
      });
    });

    it('should call an update active discussion mutation when clicking a note without moving it', () => {
      const note = notes[0];
      const { position } = note;
      const mutationVariables = {
        mutation: updateActiveDiscussion,
        variables: {
          id: note.id,
          source: ACTIVE_DISCUSSION_SOURCE_TYPES.pin,
        },
      };

      findFirstBadge().trigger('mousedown', { clientX: position.x, clientY: position.y });

      return wrapper.vm.$nextTick().then(() => {
        findFirstBadge().trigger('mouseup', { clientX: position.x, clientY: position.y });
        expect(mutate).toHaveBeenCalledWith(mutationVariables);
      });
    });
  });

  describe('when moving notes', () => {
    it('should update badge style when note is being moved', () => {
      createComponent({
        notes,
      });

      const { position } = notes[0];

      return clickAndDragBadge(
        findFirstBadge(),
        { x: position.x, y: position.y },
        { x: 20, y: 20 },
      ).then(() => {
        expect(findFirstBadge().attributes().style).toBe('left: 20px; top: 20px;');
      });
    });

    it('should emit `moveNote` event when note-moving action ends', () => {
      createComponent({ notes });
      const note = notes[0];
      const { position } = note;
      const newCoordinates = { x: 20, y: 20 };

      wrapper.setData({
        movingNoteNewPosition: {
          ...position,
          ...newCoordinates,
        },
        movingNoteStartPosition: {
          noteId: notes[0].id,
          discussionId: notes[0].discussion.id,
          ...position,
        },
      });

      const badge = findFirstBadge();
      return clickAndDragBadge(badge, { x: position.x, y: position.y }, newCoordinates)
        .then(() => {
          badge.trigger('mouseup');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
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

      it('should be unable to move a note', () => {
        createComponent({
          dimensions: mockDimensions,
          notes: [mockNoteNotAuthorised],
        });

        const badge = findAllNotes().at(0);
        return clickAndDragBadge(badge, { ...mockNoteCoordinates }, { x: 20, y: 20 }).then(() => {
          // note position should not change after a click-and-drag attempt
          expect(findFirstBadge().attributes().style).toContain(
            `left: ${mockNoteCoordinates.x}px; top: ${mockNoteCoordinates.y}px;`,
          );
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
      expect(findCommentBadge().attributes().style).toBe('left: 10px; top: 15px;');
    });

    describe('when moving the comment badge', () => {
      it('should update badge style to reflect new position', () => {
        const { position } = notes[0];

        createComponent({
          currentCommentForm: {
            ...position,
          },
        });

        return clickAndDragBadge(
          findCommentBadge(),
          { x: position.x, y: position.y },
          { x: 20, y: 20 },
        ).then(() => {
          expect(findCommentBadge().attributes().style).toBe('left: 20px; top: 20px;');
        });
      });

      it('should update badge style when note-moving action ends', () => {
        const { position } = notes[0];
        createComponent({
          currentCommentForm: {
            ...position,
          },
        });

        const commentBadge = findCommentBadge();
        const toPoint = { x: 20, y: 20 };

        return clickAndDragBadge(commentBadge, { x: position.x, y: position.y }, toPoint)
          .then(() => {
            commentBadge.trigger('mouseup');
            // simulates the currentCommentForm being updated in index.vue component, and
            // propagated back down to this prop
            wrapper.setProps({
              currentCommentForm: { height: position.height, width: position.width, ...toPoint },
            });
            return wrapper.vm.$nextTick();
          })
          .then(() => {
            expect(commentBadge.attributes().style).toBe('left: 20px; top: 20px;');
          });
      });

      it.each`
        element            | getElementFunc      | event
        ${'overlay'}       | ${() => wrapper}    | ${'mouseleave'}
        ${'comment badge'} | ${findCommentBadge} | ${'mouseup'}
      `(
        'should emit `openCommentForm` event when $event fired on $element element',
        ({ getElementFunc, event }) => {
          createComponent({
            notes,
            currentCommentForm: {
              ...notes[0].position,
            },
          });

          const newCoordinates = { x: 20, y: 20 };
          wrapper.setData({
            movingNoteStartPosition: {
              ...notes[0].position,
            },
            movingNoteNewPosition: {
              ...notes[0].position,
              ...newCoordinates,
            },
          });

          getElementFunc().trigger(event);
          return wrapper.vm.$nextTick().then(() => {
            expect(wrapper.emitted('openCommentForm')).toEqual([[newCoordinates]]);
          });
        },
      );
    });
  });

  describe('getMovingNotePositionDelta', () => {
    it('should calculate delta correctly from state', () => {
      createComponent();

      wrapper.setData({
        movingNoteStartPosition: {
          clientX: 10,
          clientY: 20,
        },
      });

      const mockMouseEvent = {
        clientX: 30,
        clientY: 10,
      };

      expect(wrapper.vm.getMovingNotePositionDelta(mockMouseEvent)).toEqual({
        deltaX: 20,
        deltaY: -10,
      });
    });
  });

  describe('isPositionInOverlay', () => {
    createComponent({ dimensions: mockDimensions });

    it.each`
      test                        | coordinates           | expectedResult
      ${'within overlay bounds'}  | ${{ x: 50, y: 50 }}   | ${true}
      ${'outside overlay bounds'} | ${{ x: 101, y: 101 }} | ${false}
    `('returns [$expectedResult] when position is $test', ({ coordinates, expectedResult }) => {
      const position = { ...mockDimensions, ...coordinates };

      expect(wrapper.vm.isPositionInOverlay(position)).toBe(expectedResult);
    });
  });

  describe('getNoteRelativePosition', () => {
    it('calculates position correctly', () => {
      createComponent({ dimensions: mockDimensions });
      const position = { x: 50, y: 50, width: 200, height: 200 };

      expect(wrapper.vm.getNoteRelativePosition(position)).toEqual({ left: 25, top: 25 });
    });
  });

  describe('canMoveNote', () => {
    it.each`
      repositionNotePermission | canMoveNoteResult
      ${true}                  | ${true}
      ${false}                 | ${false}
      ${undefined}             | ${false}
    `(
      'returns [$canMoveNoteResult] when [repositionNote permission] is [$repositionNotePermission]',
      ({ repositionNotePermission, canMoveNoteResult }) => {
        createComponent();

        const note = {
          userPermissions: {
            repositionNote: repositionNotePermission,
          },
        };
        expect(wrapper.vm.canMoveNote(note)).toBe(canMoveNoteResult);
      },
    );
  });
});

import { mount } from '@vue/test-utils';
import DesignOverlay from '~/design_management/components/design_overlay.vue';
import notes from '../mock_data/notes';

describe('Design overlay component', () => {
  let wrapper;

  const mockDimensions = { width: 100, height: 100 };
  const mockNoteNotAuthorised = {
    id: 'note-not-authorised',
    discussion: { id: 'discussion-not-authorised' },
    position: {
      x: 1,
      y: 80,
      ...mockDimensions,
    },
    userPermissions: {},
  };

  const findOverlay = () => wrapper.find('.image-diff-overlay');
  const findAllNotes = () => wrapper.findAll('.js-image-badge');
  const findCommentBadge = () => wrapper.find('.comment-indicator');
  const findFirstBadge = () => findAllNotes().at(0);
  const findSecondBadge = () => findAllNotes().at(1);

  const clickAndDragBadge = (elem, fromPoint, toPoint) => {
    elem.trigger('mousedown', { clientX: fromPoint.x, clientY: fromPoint.y });
    return wrapper.vm.$nextTick().then(() => {
      elem.trigger('mousemove', { clientX: toPoint.x, clientY: toPoint.y });
      return wrapper.vm.$nextTick();
    });
  };

  function createComponent(props = {}) {
    wrapper = mount(DesignOverlay, {
      propsData: {
        dimensions: mockDimensions,
        position: {
          top: '0',
          left: '0',
        },
        ...props,
      },
    });
  }

  it('should have correct inline style', () => {
    createComponent();

    expect(wrapper.find('.image-diff-overlay').attributes().style).toBe(
      'width: 100px; height: 100px; top: 0px; left: 0px;',
    );
  });

  it('should emit `openCommentForm` when clicking on overlay', () => {
    createComponent();
    const newCoordinates = {
      x: 10,
      y: 10,
    };

    wrapper
      .find('.image-diff-overlay-add-comment')
      .trigger('mouseup', { offsetX: newCoordinates.x, offsetY: newCoordinates.y });
    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted('openCommentForm')).toEqual([
        [{ x: newCoordinates.x, y: newCoordinates.y }],
      ]);
    });
  });

  describe('with notes', () => {
    beforeEach(() => {
      createComponent({
        notes,
      });
    });

    it('should render a correct amount of notes', () => {
      expect(findAllNotes()).toHaveLength(notes.length);
    });

    it('should have a correct style for each note badge', () => {
      expect(findFirstBadge().attributes().style).toBe('left: 10px; top: 15px;');
      expect(findSecondBadge().attributes().style).toBe('left: 50px; top: 50px;');
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
        expect(findFirstBadge().attributes().style).toBe('left: 20px; top: 20px; cursor: move;');
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

    it('should do nothing if [adminNote] permission is not present', () => {
      createComponent({
        dimensions: mockDimensions,
        notes: [mockNoteNotAuthorised],
      });

      const badge = findAllNotes().at(0);
      return clickAndDragBadge(
        badge,
        { x: mockNoteNotAuthorised.x, y: mockNoteNotAuthorised.y },
        { x: 20, y: 20 },
      ).then(() => {
        expect(wrapper.vm.movingNoteStartPosition).toBeNull();
        expect(findFirstBadge().attributes().style).toBe('left: 1px; top: 80px;');
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
          expect(findCommentBadge().attributes().style).toBe(
            'left: 20px; top: 20px; cursor: move;',
          );
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
        ${'overlay'}       | ${findOverlay}      | ${'mouseleave'}
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
      adminNotePermission | canMoveNoteResult
      ${true}             | ${true}
      ${false}            | ${false}
      ${undefined}        | ${false}
    `(
      'returns [$canMoveNoteResult] when [adminNote permission] is [$adminNotePermission]',
      ({ adminNotePermission, canMoveNoteResult }) => {
        createComponent();

        const note = {
          userPermissions: {
            adminNote: adminNotePermission,
          },
        };
        expect(wrapper.vm.canMoveNote(note)).toBe(canMoveNoteResult);
      },
    );
  });
});

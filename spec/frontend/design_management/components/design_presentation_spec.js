import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DesignOverlay from '~/design_management/components/design_overlay.vue';
import DesignPresentation from '~/design_management/components/design_presentation.vue';

const mockOverlayData = {
  overlayDimensions: {
    width: 100,
    height: 100,
  },
  overlayPosition: {
    top: '0',
    left: '0',
  },
};

describe('Design management design presentation component', () => {
  let wrapper;

  function createComponent(
    {
      image,
      imageName,
      discussions = [],
      isAnnotating = false,
      resolvedDiscussionsExpanded = false,
    } = {},
    data = {},
    stubs = {},
  ) {
    wrapper = shallowMount(DesignPresentation, {
      propsData: {
        image,
        imageName,
        discussions,
        isAnnotating,
        resolvedDiscussionsExpanded,
      },
      stubs,
    });

    wrapper.setData(data);
    wrapper.element.scrollTo = jest.fn();
  }

  const findOverlayCommentButton = () => wrapper.find('[data-qa-selector="design_image_button"]');

  /**
   * Spy on $refs and mock given values
   * @param {Object} viewportDimensions {width, height}
   * @param {Object} childDimensions {width, height}
   * @param {Float} scrollTopPerc 0 < x < 1
   * @param {Float} scrollLeftPerc  0 < x < 1
   */
  function mockRefDimensions(
    ref,
    viewportDimensions,
    childDimensions,
    scrollTopPerc,
    scrollLeftPerc,
  ) {
    jest.spyOn(ref, 'scrollWidth', 'get').mockReturnValue(childDimensions.width);
    jest.spyOn(ref, 'scrollHeight', 'get').mockReturnValue(childDimensions.height);
    jest.spyOn(ref, 'offsetWidth', 'get').mockReturnValue(viewportDimensions.width);
    jest.spyOn(ref, 'offsetHeight', 'get').mockReturnValue(viewportDimensions.height);
    jest
      .spyOn(ref, 'scrollLeft', 'get')
      .mockReturnValue((childDimensions.width - viewportDimensions.width) * scrollLeftPerc);
    jest
      .spyOn(ref, 'scrollTop', 'get')
      .mockReturnValue((childDimensions.height - viewportDimensions.height) * scrollTopPerc);
  }

  function clickDragExplore(startCoords, endCoords, { useTouchEvents, mouseup } = {}) {
    const event = useTouchEvents
      ? {
          mousedown: 'touchstart',
          mousemove: 'touchmove',
          mouseup: 'touchend',
        }
      : {
          mousedown: 'mousedown',
          mousemove: 'mousemove',
          mouseup: 'mouseup',
        };

    const addCommentOverlay = findOverlayCommentButton();

    // triggering mouse events on this element best simulates
    // reality, as it is the lowest-level node that needs to
    // respond to mouse events
    addCommentOverlay.trigger(event.mousedown, {
      clientX: startCoords.clientX,
      clientY: startCoords.clientY,
    });
    return wrapper.vm
      .$nextTick()
      .then(() => {
        addCommentOverlay.trigger(event.mousemove, {
          clientX: endCoords.clientX,
          clientY: endCoords.clientY,
        });

        return nextTick();
      })
      .then(() => {
        if (mouseup) {
          addCommentOverlay.trigger(event.mouseup);
          return nextTick();
        }

        return undefined;
      });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders image and overlay when image provided', () => {
    createComponent(
      {
        image: 'test.jpg',
        imageName: 'test',
      },
      mockOverlayData,
    );

    return nextTick().then(() => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  it('renders empty state when no image provided', () => {
    createComponent();

    return nextTick().then(() => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  it('openCommentForm event emits correct data', () => {
    createComponent(
      {
        image: 'test.jpg',
        imageName: 'test',
      },
      mockOverlayData,
    );

    wrapper.vm.openCommentForm({ x: 1, y: 1 });

    return nextTick().then(() => {
      expect(wrapper.emitted('openCommentForm')).toEqual([
        [{ ...mockOverlayData.overlayDimensions, x: 1, y: 1 }],
      ]);
    });
  });

  describe('currentCommentForm', () => {
    it('is null when isAnnotating is false', () => {
      createComponent(
        {
          image: 'test.jpg',
          imageName: 'test',
        },
        mockOverlayData,
      );

      return nextTick().then(() => {
        expect(wrapper.vm.currentCommentForm).toBeNull();
        expect(wrapper.element).toMatchSnapshot();
      });
    });

    it('is null when isAnnotating is true but annotation position is falsey', () => {
      createComponent(
        {
          image: 'test.jpg',
          imageName: 'test',
          isAnnotating: true,
        },
        mockOverlayData,
      );

      return nextTick().then(() => {
        expect(wrapper.vm.currentCommentForm).toBeNull();
        expect(wrapper.element).toMatchSnapshot();
      });
    });

    it('is equal to current annotation position when isAnnotating is true', () => {
      createComponent(
        {
          image: 'test.jpg',
          imageName: 'test',
          isAnnotating: true,
        },
        {
          ...mockOverlayData,
          currentAnnotationPosition: {
            x: 1,
            y: 1,
            width: 100,
            height: 100,
          },
        },
      );

      return nextTick().then(() => {
        expect(wrapper.vm.currentCommentForm).toEqual({
          x: 1,
          y: 1,
          width: 100,
          height: 100,
        });
        expect(wrapper.element).toMatchSnapshot();
      });
    });
  });

  describe('setOverlayPosition', () => {
    beforeEach(() => {
      createComponent(
        {
          image: 'test.jpg',
          imageName: 'test',
        },
        mockOverlayData,
      );
    });

    afterEach(() => {
      jest.clearAllMocks();
    });

    it('sets overlay position correctly when overlay is smaller than viewport', () => {
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetWidth', 'get').mockReturnValue(200);
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetHeight', 'get').mockReturnValue(200);

      wrapper.vm.setOverlayPosition();
      expect(wrapper.vm.overlayPosition).toEqual({
        left: `calc(50% - ${mockOverlayData.overlayDimensions.width / 2}px)`,
        top: `calc(50% - ${mockOverlayData.overlayDimensions.height / 2}px)`,
      });
    });

    it('sets overlay position correctly when overlay width is larger than viewports', () => {
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetWidth', 'get').mockReturnValue(50);
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetHeight', 'get').mockReturnValue(200);

      wrapper.vm.setOverlayPosition();
      expect(wrapper.vm.overlayPosition).toEqual({
        left: '0',
        top: `calc(50% - ${mockOverlayData.overlayDimensions.height / 2}px)`,
      });
    });

    it('sets overlay position correctly when overlay height is larger than viewports', () => {
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetWidth', 'get').mockReturnValue(200);
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetHeight', 'get').mockReturnValue(50);

      wrapper.vm.setOverlayPosition();
      expect(wrapper.vm.overlayPosition).toEqual({
        left: `calc(50% - ${mockOverlayData.overlayDimensions.width / 2}px)`,
        top: '0',
      });
    });
  });

  describe('getViewportCenter', () => {
    beforeEach(() => {
      createComponent(
        {
          image: 'test.jpg',
          imageName: 'test',
        },
        mockOverlayData,
      );
    });

    it('calculate center correctly with no scroll', () => {
      mockRefDimensions(
        wrapper.vm.$refs.presentationViewport,
        { width: 10, height: 10 },
        { width: 20, height: 20 },
        0,
        0,
      );

      expect(wrapper.vm.getViewportCenter()).toEqual({
        x: 5,
        y: 5,
      });
    });

    it('calculate center correctly with some scroll', () => {
      mockRefDimensions(
        wrapper.vm.$refs.presentationViewport,
        { width: 10, height: 10 },
        { width: 20, height: 20 },
        0.5,
        0.5,
      );

      expect(wrapper.vm.getViewportCenter()).toEqual({
        x: 10,
        y: 10,
      });
    });

    it('Returns default case if no overflow (scrollWidth==offsetWidth, etc.)', () => {
      mockRefDimensions(
        wrapper.vm.$refs.presentationViewport,
        { width: 20, height: 20 },
        { width: 20, height: 20 },
        0.5,
        0.5,
      );

      expect(wrapper.vm.getViewportCenter()).toEqual({
        x: 10,
        y: 10,
      });
    });
  });

  describe('scaleZoomFocalPoint', () => {
    it('scales focal point correctly when zooming in', () => {
      createComponent(
        {
          image: 'test.jpg',
          imageName: 'test',
        },
        {
          ...mockOverlayData,
          zoomFocalPoint: {
            x: 5,
            y: 5,
            width: 50,
            height: 50,
          },
        },
      );

      wrapper.vm.scaleZoomFocalPoint();
      expect(wrapper.vm.zoomFocalPoint).toEqual({
        x: 10,
        y: 10,
        width: 100,
        height: 100,
      });
    });

    it('scales focal point correctly when zooming out', () => {
      createComponent(
        {
          image: 'test.jpg',
          imageName: 'test',
        },
        {
          ...mockOverlayData,
          zoomFocalPoint: {
            x: 10,
            y: 10,
            width: 200,
            height: 200,
          },
        },
      );

      wrapper.vm.scaleZoomFocalPoint();
      expect(wrapper.vm.zoomFocalPoint).toEqual({
        x: 5,
        y: 5,
        width: 100,
        height: 100,
      });
    });
  });

  describe('onImageResize', () => {
    beforeEach(() => {
      createComponent(
        {
          image: 'test.jpg',
          imageName: 'test',
        },
        mockOverlayData,
      );

      jest.spyOn(wrapper.vm, 'shiftZoomFocalPoint');
      jest.spyOn(wrapper.vm, 'scaleZoomFocalPoint');
      jest.spyOn(wrapper.vm, 'scrollToFocalPoint');
      wrapper.vm.onImageResize({ width: 10, height: 10 });
      return nextTick();
    });

    it('sets zoom focal point on initial load', () => {
      expect(wrapper.vm.shiftZoomFocalPoint).toHaveBeenCalled();
      expect(wrapper.vm.initialLoad).toBe(false);
    });

    it('calls scaleZoomFocalPoint and scrollToFocalPoint after initial load', () => {
      wrapper.vm.onImageResize({ width: 10, height: 10 });
      return nextTick().then(() => {
        expect(wrapper.vm.scaleZoomFocalPoint).toHaveBeenCalled();
        expect(wrapper.vm.scrollToFocalPoint).toHaveBeenCalled();
      });
    });
  });

  describe('onPresentationMousedown', () => {
    it.each`
      scenario                        | width  | height
      ${'width overflows'}            | ${101} | ${100}
      ${'height overflows'}           | ${100} | ${101}
      ${'width and height overflows'} | ${200} | ${200}
    `('sets lastDragPosition when design $scenario', ({ width, height }) => {
      createComponent();
      mockRefDimensions(
        wrapper.vm.$refs.presentationViewport,
        { width: 100, height: 100 },
        { width, height },
      );

      const newLastDragPosition = { x: 2, y: 2 };
      wrapper.vm.onPresentationMousedown({
        clientX: newLastDragPosition.x,
        clientY: newLastDragPosition.y,
      });

      expect(wrapper.vm.lastDragPosition).toStrictEqual(newLastDragPosition);
    });

    it('does not set lastDragPosition if design does not overflow', () => {
      const lastDragPosition = { x: 1, y: 1 };

      createComponent({}, { lastDragPosition });
      mockRefDimensions(
        wrapper.vm.$refs.presentationViewport,
        { width: 100, height: 100 },
        { width: 50, height: 50 },
      );

      wrapper.vm.onPresentationMousedown({ clientX: 2, clientY: 2 });

      // check lastDragPosition is unchanged
      expect(wrapper.vm.lastDragPosition).toStrictEqual(lastDragPosition);
    });
  });

  describe('getAnnotationPositon', () => {
    it.each`
      coordinates               | overlayDimensions                | position
      ${{ x: 100, y: 100 }}     | ${{ width: 50, height: 50 }}     | ${{ x: 100, y: 100, width: 50, height: 50 }}
      ${{ x: 100.2, y: 100.5 }} | ${{ width: 50.6, height: 50.0 }} | ${{ x: 100, y: 101, width: 51, height: 50 }}
    `('returns correct annotation position', ({ coordinates, overlayDimensions, position }) => {
      createComponent(undefined, {
        overlayDimensions: {
          width: overlayDimensions.width,
          height: overlayDimensions.height,
        },
      });

      expect(wrapper.vm.getAnnotationPositon(coordinates)).toStrictEqual(position);
    });
  });

  describe('when design is overflowing', () => {
    beforeEach(() => {
      createComponent(
        {
          image: 'test.jpg',
          imageName: 'test',
        },
        mockOverlayData,
        {
          'design-overlay': DesignOverlay,
        },
      );

      // mock a design that overflows
      mockRefDimensions(
        wrapper.vm.$refs.presentationViewport,
        { width: 10, height: 10 },
        { width: 20, height: 20 },
        0,
        0,
      );
    });

    it('opens a comment form if design was not dragged', () => {
      const addCommentOverlay = findOverlayCommentButton();
      const startCoords = {
        clientX: 1,
        clientY: 1,
      };

      addCommentOverlay.trigger('mousedown', {
        clientX: startCoords.clientX,
        clientY: startCoords.clientY,
      });

      return wrapper.vm
        .$nextTick()
        .then(() => {
          addCommentOverlay.trigger('mouseup');
          return nextTick();
        })
        .then(() => {
          expect(wrapper.emitted('openCommentForm')).toBeDefined();
        });
    });

    describe('when clicking and dragging', () => {
      it.each`
        description               | useTouchEvents
        ${'with touch events'}    | ${true}
        ${'without touch events'} | ${false}
      `('calls scrollTo with correct arguments $description', ({ useTouchEvents }) => {
        return clickDragExplore(
          { clientX: 0, clientY: 0 },
          { clientX: 10, clientY: 10 },
          { useTouchEvents },
        ).then(() => {
          expect(wrapper.element.scrollTo).toHaveBeenCalledTimes(1);
          expect(wrapper.element.scrollTo).toHaveBeenCalledWith(-10, -10);
        });
      });

      it('does not open a comment form when drag position exceeds buffer', () => {
        return clickDragExplore(
          { clientX: 0, clientY: 0 },
          { clientX: 10, clientY: 10 },
          { mouseup: true },
        ).then(() => {
          expect(wrapper.emitted('openCommentForm')).toBeFalsy();
        });
      });

      it('opens a comment form when drag position is within buffer', () => {
        return clickDragExplore(
          { clientX: 0, clientY: 0 },
          { clientX: 1, clientY: 0 },
          { mouseup: true },
        ).then(() => {
          expect(wrapper.emitted('openCommentForm')).toBeDefined();
        });
      });
    });
  });
});

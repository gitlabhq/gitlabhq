import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DesignOverlay from '~/design_management/components/design_overlay.vue';
import DesignPresentation from '~/design_management/components/design_presentation.vue';
import DesignImage from '~/design_management/components/image.vue';

const mockOverlayDimensions = {
  width: 100,
  height: 100,
};

describe('Design management design presentation component', () => {
  let wrapper;

  const findDesignImage = () => wrapper.findComponent(DesignImage);
  const findDesignOverlay = () => wrapper.findComponent(DesignOverlay);
  const findOverlayCommentButton = () => wrapper.find('[data-testid="design-image-button"]');

  function createComponent(props = {}, initialOverlayDimensions = mockOverlayDimensions, options) {
    wrapper = shallowMount(DesignPresentation, {
      propsData: {
        image: 'test.jpg',
        imageName: 'test',
        resolvedDiscussionsExpanded: false,
        discussions: [],
        isLoading: false,
        disableCommenting: false,
        ...props,
      },
      ...options,
    });

    if (initialOverlayDimensions) {
      findDesignImage().vm.$emit('resize', initialOverlayDimensions);
    }

    wrapper.element.scrollTo = jest.fn();
  }

  /**
   * Spy on $refs and mock given values
   * @param {Object} viewportDimensions {width, height}
   * @param {Object} childDimensions {width, height}
   * @param {Float} scrollTopPerc 0 < x < 1
   * @param {Float} scrollLeftPerc  0 < x < 1
   */
  // eslint-disable-next-line max-params
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

  async function clickDragExplore(startCoords, endCoords, { useTouchEvents, mouseup } = {}) {
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
    await nextTick();
    addCommentOverlay.trigger(event.mousemove, {
      clientX: endCoords.clientX,
      clientY: endCoords.clientY,
    });

    await nextTick();
    if (mouseup) {
      addCommentOverlay.trigger(event.mouseup);
      await nextTick();
    }
  }

  beforeEach(() => {
    window.gon = { current_user_id: 1 };
  });

  it('renders image and overlay when image provided', async () => {
    createComponent({
      image: 'test.jpg',
      imageName: 'test',
    });

    await nextTick();
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders empty state when no image provided', async () => {
    createComponent(
      {
        image: '',
        imageName: '',
      },
      null,
    );

    await nextTick();
    expect(wrapper.element).toMatchSnapshot();
  });

  it('openCommentForm event emits correct data', async () => {
    createComponent({
      image: 'test.jpg',
      imageName: 'test',
    });

    wrapper.vm.openCommentForm({ x: 1, y: 1 });

    await nextTick();
    expect(wrapper.emitted('openCommentForm')).toEqual([
      [{ ...mockOverlayDimensions, x: 1, y: 1 }],
    ]);
  });

  describe('currentCommentForm', () => {
    it('is null when isAnnotating is false', async () => {
      createComponent({
        image: 'test.jpg',
        imageName: 'test',
      });

      await nextTick();
      expect(findDesignOverlay().props('currentCommentForm')).toBeNull();
      expect(wrapper.element).toMatchSnapshot();
    });

    it('is null when isAnnotating is true but annotation position is falsey', async () => {
      createComponent({
        image: 'test.jpg',
        imageName: 'test',
        isAnnotating: true,
      });

      await nextTick();
      expect(findDesignOverlay().props('currentCommentForm')).toBeNull();
      expect(wrapper.element).toMatchSnapshot();
    });

    it('is equal to current annotation position when isAnnotating is true', async () => {
      createComponent({
        image: 'test.jpg',
        imageName: 'test',
        isAnnotating: true,
      });

      await nextTick();
      findDesignOverlay().vm.$emit('openCommentForm', {
        x: 1,
        y: 1,
      });

      await nextTick();
      expect(findDesignOverlay().props('currentCommentForm')).toEqual({
        x: 1,
        y: 1,
        width: 100,
        height: 100,
      });

      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('setOverlayPosition', () => {
    beforeEach(() => {
      createComponent({
        image: 'test.jpg',
        imageName: 'test',
      });
    });

    it('sets overlay position correctly when overlay is smaller than viewport', async () => {
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetWidth', 'get').mockReturnValue(200);
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetHeight', 'get').mockReturnValue(200);
      wrapper.vm.setOverlayPosition();

      await nextTick();
      expect(findDesignOverlay().props('position')).toEqual({
        left: `calc(50% - ${mockOverlayDimensions.width / 2}px)`,
        top: `calc(50% - ${mockOverlayDimensions.height / 2}px)`,
      });
    });

    it('sets overlay position correctly when overlay width is larger than viewports', async () => {
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetWidth', 'get').mockReturnValue(50);
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetHeight', 'get').mockReturnValue(200);
      wrapper.vm.setOverlayPosition();

      await nextTick();
      expect(findDesignOverlay().props('position')).toEqual({
        left: `0`,
        top: `calc(50% - ${mockOverlayDimensions.height / 2}px)`,
      });
    });

    it('sets overlay position correctly when overlay height is larger than viewports', async () => {
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetWidth', 'get').mockReturnValue(200);
      jest.spyOn(wrapper.vm.$refs.presentationViewport, 'offsetHeight', 'get').mockReturnValue(50);
      wrapper.vm.setOverlayPosition();

      await nextTick();
      expect(findDesignOverlay().props('position')).toEqual({
        left: `calc(50% - ${mockOverlayDimensions.width / 2}px)`,
        top: '0',
      });
    });
  });

  describe('getViewportCenter', () => {
    beforeEach(() => {
      createComponent({
        image: 'test.jpg',
        imageName: 'test',
      });
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
      createComponent({
        image: 'test.jpg',
        imageName: 'test',
      });

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        zoomFocalPoint: {
          x: 5,
          y: 5,
          width: 50,
          height: 50,
        },
      });
      wrapper.vm.scaleZoomFocalPoint();
      expect(wrapper.vm.zoomFocalPoint).toEqual({
        x: 10,
        y: 10,
        width: 100,
        height: 100,
      });
    });

    it('scales focal point correctly when zooming out', () => {
      createComponent({
        image: 'test.jpg',
        imageName: 'test',
      });

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        zoomFocalPoint: {
          x: 10,
          y: 10,
          width: 200,
          height: 200,
        },
      });
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
    beforeEach(async () => {
      createComponent({
        image: 'test.jpg',
        imageName: 'test',
      });

      jest.spyOn(wrapper.vm, 'shiftZoomFocalPoint');
      jest.spyOn(wrapper.vm, 'scaleZoomFocalPoint');
      jest.spyOn(wrapper.vm, 'scrollToFocalPoint');
      wrapper.vm.onImageResize({ width: 10, height: 10 });
      await nextTick();
    });

    it('sets zoom focal point on initial load', () => {
      expect(wrapper.vm.shiftZoomFocalPoint).toHaveBeenCalled();
      expect(wrapper.vm.initialLoad).toBe(false);
    });

    it('calls scaleZoomFocalPoint and scrollToFocalPoint after initial load', async () => {
      wrapper.vm.onImageResize({ width: 10, height: 10 });
      await nextTick();
      expect(wrapper.vm.scaleZoomFocalPoint).toHaveBeenCalled();
      expect(wrapper.vm.scrollToFocalPoint).toHaveBeenCalled();
    });
  });

  describe('onPresentationMousedown', () => {
    it.each`
      scenario                        | width  | height
      ${'width overflows'}            | ${101} | ${100}
      ${'height overflows'}           | ${100} | ${101}
      ${'width and height overflows'} | ${200} | ${200}
    `('sets lastDragPosition when design $scenario', ({ width, height }) => {
      createComponent(
        {
          image: '',
          imageName: '',
        },
        null,
      );
      mockRefDimensions(
        wrapper.vm.$refs.presentationViewport,
        { width: 100, height: 100 },
        { width, height },
      );

      const newLastDragPosition = { x: 2, y: 2 };
      wrapper.trigger('mousedown', {
        clientX: newLastDragPosition.x,
        clientY: newLastDragPosition.y,
      });

      expect(wrapper.vm.lastDragPosition).toStrictEqual(newLastDragPosition);
    });

    it('does not set lastDragPosition if design does not overflow', () => {
      const lastDragPosition = { x: 1, y: 1 };

      createComponent(
        {
          image: '',
          imageName: '',
        },
        null,
      );

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ lastDragPosition });

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
    `(
      'returns correct annotation position',
      async ({ coordinates, overlayDimensions, position }) => {
        createComponent(
          {
            image: 'test.jpg',
            imageName: 'test',
          },
          overlayDimensions,
        );

        await nextTick();
        expect(wrapper.vm.getAnnotationPositon(coordinates)).toStrictEqual(position);
      },
    );
  });

  describe('when design is overflowing', () => {
    beforeEach(() => {
      createComponent(
        {
          image: 'test.jpg',
          imageName: 'test',
        },
        mockOverlayDimensions,
        {
          stubs: { DesignOverlay },
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

    it('opens a comment form if design was not dragged', async () => {
      const addCommentOverlay = findOverlayCommentButton();
      const startCoords = {
        clientX: 1,
        clientY: 1,
      };

      addCommentOverlay.trigger('mousedown', {
        clientX: startCoords.clientX,
        clientY: startCoords.clientY,
      });

      await nextTick();
      addCommentOverlay.trigger('mouseup');
      await nextTick();
      expect(wrapper.emitted('openCommentForm')).toBeDefined();
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
          expect(wrapper.emitted('openCommentForm')).toBeUndefined();
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

  describe('when user is not logged in', () => {
    beforeEach(() => {
      window.gon = { current_user_id: null };
      createComponent({
        image: 'test.jpg',
        imageName: 'test',
      });
    });

    it('disables commenting from design overlay', () => {
      expect(findDesignOverlay().props('disableCommenting')).toEqual(true);
    });
  });
});

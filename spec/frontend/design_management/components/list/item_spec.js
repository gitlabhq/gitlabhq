import { GlIcon, GlLoadingIcon, GlIntersectionObserver } from '@gitlab/ui';
import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueRouter from 'vue-router';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import Item from '~/design_management/components/list/item.vue';

Vue.use(VueRouter);
const router = new VueRouter();

// Referenced from: gitlab_schema.graphql:DesignVersionEvent
const DESIGN_VERSION_EVENT = {
  CREATION: 'CREATION',
  DELETION: 'DELETION',
  MODIFICATION: 'MODIFICATION',
  NO_CHANGE: 'NONE',
};

describe('Design management list item component', () => {
  let wrapper;
  const imgId = 1;
  const imgFilename = 'test';

  const findDesignEvent = () => wrapper.findByTestId('design-event');
  const findImgFilename = (id = imgId) => wrapper.findByTestId(`design-img-filename-${id}`);
  const findEventIcon = () => findDesignEvent().findComponent(GlIcon);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  function createComponent({
    notesCount = 0,
    event = DESIGN_VERSION_EVENT.NO_CHANGE,
    isUploading = false,
    imageLoading = false,
  } = {}) {
    wrapper = extendedWrapper(
      shallowMount(Item, {
        router,
        propsData: {
          id: imgId,
          filename: imgFilename,
          image: 'http://via.placeholder.com/300',
          isUploading,
          event,
          notesCount,
          updatedAt: '01-01-2019',
        },
        data() {
          return {
            imageLoading,
          };
        },
        stubs: { RouterLink: RouterLinkStub },
      }),
    );
  }

  describe('when item is not in view', () => {
    it('image is not rendered', () => {
      createComponent();

      const imageSrc = wrapper.find('img').element.src;

      /**
       * Test for <img> tag source handling.
       * When running this spec in Vue 3 mode, the src attribute
       * of the image element is null. While in browser `img.src` would
       * be an empty string, in `jsdom` it can be `null`.
       */
      expect(imageSrc === '' || imageSrc === null).toBe(true);
    });
  });

  describe('when item appears in view', () => {
    let image;
    let glIntersectionObserver;

    beforeEach(async () => {
      createComponent();
      image = wrapper.find('img');
      glIntersectionObserver = wrapper.findComponent(GlIntersectionObserver);

      glIntersectionObserver.vm.$emit('appear');
      await nextTick();
    });

    it('renders a tooltip', () => {
      expect(findImgFilename().attributes('title')).toEqual(imgFilename);
    });

    describe('before image is loaded', () => {
      it('renders loading spinner', () => {
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      });
    });

    describe('after image is loaded', () => {
      beforeEach(async () => {
        image.trigger('load');
        await nextTick();
      });

      it('renders an image', () => {
        expect(image.element.src).toBe('http://via.placeholder.com/300');
        expect(image.isVisible()).toBe(true);
      });

      it('renders media broken icon when image onerror triggered', async () => {
        image.trigger('error');
        await nextTick();
        expect(image.isVisible()).toBe(false);
        expect(wrapper.findComponent(GlIcon).element).toMatchSnapshot();
      });

      describe('when imageV432x230 and image provided', () => {
        it('renders imageV432x230 image', async () => {
          const mockSrc = 'mock-imageV432x230-url';
          wrapper.setProps({ imageV432x230: mockSrc });

          await nextTick();
          expect(image.element.src).toBe(mockSrc);
        });
      });

      describe('when image disappears from view and then reappears', () => {
        beforeEach(async () => {
          glIntersectionObserver.vm.$emit('appear');
          await nextTick();
        });

        it('renders an image', () => {
          expect(image.isVisible()).toBe(true);
        });
      });
    });
  });

  describe('with notes', () => {
    it('renders item with single comment', () => {
      createComponent({ notesCount: 1 });

      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders item with multiple comments', () => {
      createComponent({ notesCount: 2 });

      expect(wrapper.element).toMatchSnapshot();
    });
  });

  it('renders loading spinner when isUploading is true', () => {
    createComponent({ isUploading: true });

    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('renders item with no status icon for none event', () => {
    createComponent();

    expect(findDesignEvent().exists()).toBe(false);
  });

  describe('with associated event', () => {
    it.each`
      event                                | icon                     | className
      ${DESIGN_VERSION_EVENT.MODIFICATION} | ${'file-modified-solid'} | ${'gl-fill-icon-info'}
      ${DESIGN_VERSION_EVENT.DELETION}     | ${'file-deletion-solid'} | ${'gl-fill-icon-danger'}
      ${DESIGN_VERSION_EVENT.CREATION}     | ${'file-addition-solid'} | ${'gl-fill-icon-success'}
    `('renders item with correct status icon for $event event', ({ event, icon, className }) => {
      createComponent({ event });
      const eventIcon = findEventIcon();

      expect(eventIcon.exists()).toBe(true);
      expect(eventIcon.props('name')).toBe(icon);
      expect(eventIcon.classes()).toContain(className);
    });
  });
});

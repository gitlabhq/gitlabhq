import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlIcon, GlLoadingIcon, GlIntersectionObserver } from '@gitlab/ui';
import VueRouter from 'vue-router';
import Item from '~/design_management/components/list/item.vue';

const localVue = createLocalVue();
localVue.use(VueRouter);
const router = new VueRouter();

// Referenced from: doc/api/graphql/reference/gitlab_schema.graphql:DesignVersionEvent
const DESIGN_VERSION_EVENT = {
  CREATION: 'CREATION',
  DELETION: 'DELETION',
  MODIFICATION: 'MODIFICATION',
  NO_CHANGE: 'NONE',
};

describe('Design management list item component', () => {
  let wrapper;

  function createComponent({
    notesCount = 0,
    event = DESIGN_VERSION_EVENT.NO_CHANGE,
    isUploading = false,
    imageLoading = false,
  } = {}) {
    wrapper = shallowMount(Item, {
      localVue,
      router,
      propsData: {
        id: 1,
        filename: 'test',
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
      stubs: ['router-link'],
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when item is not in view', () => {
    it('image is not rendered', () => {
      createComponent();

      const image = wrapper.find('img');
      expect(image.attributes('src')).toBe('');
    });
  });

  describe('when item appears in view', () => {
    let image;
    let glIntersectionObserver;

    beforeEach(() => {
      createComponent();
      image = wrapper.find('img');
      glIntersectionObserver = wrapper.find(GlIntersectionObserver);

      glIntersectionObserver.vm.$emit('appear');
      return wrapper.vm.$nextTick();
    });

    describe('before image is loaded', () => {
      it('renders loading spinner', () => {
        expect(wrapper.find(GlLoadingIcon)).toExist();
      });
    });

    describe('after image is loaded', () => {
      beforeEach(() => {
        image.trigger('load');
        return wrapper.vm.$nextTick();
      });

      it('renders an image', () => {
        expect(image.attributes('src')).toBe('http://via.placeholder.com/300');
        expect(image.isVisible()).toBe(true);
      });

      it('renders media broken icon when image onerror triggered', () => {
        image.trigger('error');
        return wrapper.vm.$nextTick().then(() => {
          expect(image.isVisible()).toBe(false);
          expect(wrapper.find(GlIcon).element).toMatchSnapshot();
        });
      });

      describe('when imageV432x230 and image provided', () => {
        it('renders imageV432x230 image', () => {
          const mockSrc = 'mock-imageV432x230-url';
          wrapper.setProps({ imageV432x230: mockSrc });

          return wrapper.vm.$nextTick().then(() => {
            expect(image.attributes('src')).toBe(mockSrc);
          });
        });
      });

      describe('when image disappears from view and then reappears', () => {
        beforeEach(() => {
          glIntersectionObserver.vm.$emit('appear');
          return wrapper.vm.$nextTick();
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

  describe('with no notes', () => {
    it('renders item with no status icon for none event', () => {
      createComponent();

      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders item with correct status icon for modification event', () => {
      createComponent({ event: DESIGN_VERSION_EVENT.MODIFICATION });

      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders item with correct status icon for deletion event', () => {
      createComponent({ event: DESIGN_VERSION_EVENT.DELETION });

      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders item with correct status icon for creation event', () => {
      createComponent({ event: DESIGN_VERSION_EVENT.CREATION });

      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders loading spinner when isUploading is true', () => {
      createComponent({ isUploading: true });

      expect(wrapper.element).toMatchSnapshot();
    });
  });
});

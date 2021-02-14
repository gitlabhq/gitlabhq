import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DesignImage from '~/design_management/components/image.vue';

describe('Design management large image component', () => {
  let wrapper;

  function createComponent(propsData, data = {}) {
    wrapper = shallowMount(DesignImage, {
      propsData,
    });
    wrapper.setData(data);
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders loading state', () => {
    createComponent({
      isLoading: true,
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders image', () => {
    createComponent({
      isLoading: false,
      image: 'test.jpg',
      name: 'test',
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('sets correct classes and styles if imageStyle is set', () => {
    createComponent(
      {
        isLoading: false,
        image: 'test.jpg',
        name: 'test',
      },
      {
        imageStyle: {
          width: '100px',
          height: '100px',
        },
      },
    );
    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  it('renders media broken icon on error', () => {
    createComponent({
      isLoading: false,
      image: 'test.jpg',
      name: 'test',
    });

    const image = wrapper.find('img');
    image.trigger('error');
    return wrapper.vm.$nextTick().then(() => {
      expect(image.isVisible()).toBe(false);
      expect(wrapper.find(GlIcon).element).toMatchSnapshot();
    });
  });

  describe('zoom', () => {
    const baseImageWidth = 100;
    const baseImageHeight = 100;

    beforeEach(() => {
      createComponent(
        {
          isLoading: false,
          image: 'test.jpg',
          name: 'test',
        },
        {
          imageStyle: {
            width: `${baseImageWidth}px`,
            height: `${baseImageHeight}px`,
          },
          baseImageSize: {
            width: baseImageWidth,
            height: baseImageHeight,
          },
        },
      );

      jest.spyOn(wrapper.vm.$refs.contentImg, 'offsetWidth', 'get').mockReturnValue(baseImageWidth);
      jest
        .spyOn(wrapper.vm.$refs.contentImg, 'offsetHeight', 'get')
        .mockReturnValue(baseImageHeight);
    });

    it('emits @resize event on zoom', () => {
      const zoomAmount = 2;
      wrapper.vm.zoom(zoomAmount);

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('resize')).toEqual([
          [{ width: baseImageWidth * zoomAmount, height: baseImageHeight * zoomAmount }],
        ]);
      });
    });

    it('emits @resize event with base image size when scale=1', () => {
      wrapper.vm.zoom(1);

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('resize')).toEqual([
          [{ width: baseImageWidth, height: baseImageHeight }],
        ]);
      });
    });

    it('sets image style when zoomed', () => {
      const zoomAmount = 2;
      wrapper.vm.zoom(zoomAmount);
      expect(wrapper.vm.imageStyle).toEqual({
        width: `${baseImageWidth * zoomAmount}px`,
        height: `${baseImageHeight * zoomAmount}px`,
      });
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.element).toMatchSnapshot();
      });
    });
  });
});

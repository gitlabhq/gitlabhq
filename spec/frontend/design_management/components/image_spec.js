import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { stubPerformanceWebAPI } from 'helpers/performance';
import DesignImage from '~/design_management/components/image.vue';

describe('Design management large image component', () => {
  let wrapper;

  function createComponent(propsData, data = {}) {
    wrapper = shallowMount(DesignImage, {
      propsData,
    });
    // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
    // eslint-disable-next-line no-restricted-syntax
    wrapper.setData(data);
  }

  beforeEach(() => {
    stubPerformanceWebAPI();
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

  it('renders SVG with proper height and width', () => {
    createComponent({
      isLoading: false,
      image: 'mockImage.svg',
      name: 'test',
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('sets correct classes and styles if imageStyle is set', async () => {
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
    await nextTick();
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders media broken icon on error', async () => {
    createComponent({
      isLoading: false,
      image: 'test.jpg',
      name: 'test',
    });

    const image = wrapper.find('img');
    image.trigger('error');
    await nextTick();
    expect(image.isVisible()).toBe(false);
    expect(wrapper.findComponent(GlIcon).element).toMatchSnapshot();
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

    it('emits @resize event on zoom', async () => {
      const zoomAmount = 2;
      wrapper.vm.zoom(zoomAmount);

      await nextTick();
      expect(wrapper.emitted('resize')).toEqual([
        [{ width: baseImageWidth * zoomAmount, height: baseImageHeight * zoomAmount }],
      ]);
    });

    it('emits @resize event with base image size when scale=1', async () => {
      wrapper.vm.zoom(1);

      await nextTick();
      expect(wrapper.emitted('resize')).toEqual([
        [{ width: baseImageWidth, height: baseImageHeight }],
      ]);
    });

    it('sets image style when zoomed', async () => {
      const zoomAmount = 2;
      wrapper.vm.zoom(zoomAmount);
      expect(wrapper.vm.imageStyle).toEqual({
        width: `${baseImageWidth * zoomAmount}px`,
        height: `${baseImageHeight * zoomAmount}px`,
      });
      await nextTick();
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});

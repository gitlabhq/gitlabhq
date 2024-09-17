import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GREEN_BOX_IMAGE_URL, RED_BOX_IMAGE_URL } from 'spec/test_constants';
import ImageDiffViewer from '~/vue_shared/components/diff_viewer/viewers/image_diff_viewer.vue';

describe('ImageDiffViewer component', () => {
  const requiredProps = {
    diffMode: 'replaced',
    newPath: GREEN_BOX_IMAGE_URL,
    oldPath: RED_BOX_IMAGE_URL,
  };
  const allProps = {
    ...requiredProps,
    oldSize: 2048,
    newSize: 1024,
  };
  let wrapper;

  const createComponent = (props, slots) => {
    wrapper = mount(ImageDiffViewer, { propsData: props, slots });
  };

  const triggerEvent = (eventName, el = wrapper.$el, clientX = 0) => {
    const event = new MouseEvent(eventName, {
      bubbles: true,
      cancelable: true,
      view: window,
      detail: 1,
      screenX: clientX,
      clientX,
    });

    // JSDOM does not implement experimental APIs
    event.pageX = clientX;

    el.dispatchEvent(event);
  };

  const dragSlider = (sliderElement, doc, dragPixel) => {
    triggerEvent('mousedown', sliderElement);
    triggerEvent('mousemove', doc.body, dragPixel);
    triggerEvent('mouseup', doc.body);
  };

  it('renders image diff for replaced', () => {
    createComponent(allProps);
    const metaInfoElements = wrapper.findAll('.image-info');

    expect(wrapper.find('.added img').element.src).toBe(GREEN_BOX_IMAGE_URL);
    expect(wrapper.find('.deleted img').element.src).toBe(RED_BOX_IMAGE_URL);
    expect(wrapper.find('.view-modes-menu li.active').text()).toBe('2-up');
    expect(wrapper.find('.view-modes-menu li:nth-child(2)').text()).toBe('Swipe');
    expect(wrapper.find('.view-modes-menu li:nth-child(3)').text()).toBe('Onion skin');
    expect(metaInfoElements).toHaveLength(2);
    expect(metaInfoElements.at(0).text()).toBe('2.00 KiB');
    expect(metaInfoElements.at(1).text()).toBe('1.00 KiB');
  });

  it('renders image diff for new', () => {
    createComponent({ ...allProps, diffMode: 'new', oldPath: '' });

    expect(wrapper.find('.added img').element.src).toBe(GREEN_BOX_IMAGE_URL);
    expect(wrapper.find('.image-info').text()).toBe('1.00 KiB');
  });

  it('renders image diff for deleted', () => {
    createComponent({ ...allProps, diffMode: 'deleted', newPath: '' });

    expect(wrapper.find('.deleted img').element.src).toBe(RED_BOX_IMAGE_URL);
    expect(wrapper.find('.image-info').text()).toBe('2.00 KiB');
  });

  it('renders image diff for renamed', () => {
    createComponent(
      { ...allProps, diffMode: 'renamed' },
      { 'image-overlay': '<span class="overlay">test</span>' },
    );

    expect(wrapper.find('img').element.src).toBe(GREEN_BOX_IMAGE_URL);
    expect(wrapper.find('.overlay').exists()).toBe(true);
    expect(wrapper.find('.image-info').text()).toBe('2.00 KiB');
  });

  describe('swipeMode', () => {
    beforeEach(() => {
      createComponent(requiredProps);
    });

    it('switches to Swipe Mode', async () => {
      await wrapper.find('.view-modes-menu li:nth-child(2)').trigger('click');

      expect(wrapper.find('.view-modes-menu li.active').text()).toBe('Swipe');
    });
  });

  describe('onionSkin', () => {
    beforeEach(() => {
      createComponent({ ...requiredProps });
    });

    it('switches to Onion Skin Mode', async () => {
      await wrapper.find('.view-modes-menu li:nth-child(3)').trigger('click');

      expect(wrapper.find('.view-modes-menu li.active').text()).toBe('Onion skin');
    });

    it('has working drag handler', async () => {
      await wrapper.find('.view-modes-menu li:nth-child(3)').trigger('click');

      dragSlider(wrapper.find('.dragger').element, document, 20);
      await nextTick();

      expect(wrapper.find('.dragger').attributes('style')).toBe('left: 20px;');
      expect(wrapper.find('.added.frame').attributes('style')).toBe('opacity: 0.2;');
    });
  });
});

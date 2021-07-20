import { mount } from '@vue/test-utils';
import Vue from 'vue';
import { compileToFunctions } from 'vue-template-compiler';

import { GREEN_BOX_IMAGE_URL, RED_BOX_IMAGE_URL } from 'spec/test_constants';
import imageDiffViewer from '~/vue_shared/components/diff_viewer/viewers/image_diff_viewer.vue';

describe('ImageDiffViewer', () => {
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
  let vm;

  function createComponent(props) {
    const ImageDiffViewer = Vue.extend(imageDiffViewer);
    wrapper = mount(ImageDiffViewer, { propsData: props });
    vm = wrapper.vm;
  }

  const triggerEvent = (eventName, el = vm.$el, clientX = 0) => {
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

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders image diff for replaced', (done) => {
    createComponent({ ...allProps });

    vm.$nextTick(() => {
      const metaInfoElements = vm.$el.querySelectorAll('.image-info');

      expect(vm.$el.querySelector('.added img').getAttribute('src')).toBe(GREEN_BOX_IMAGE_URL);

      expect(vm.$el.querySelector('.deleted img').getAttribute('src')).toBe(RED_BOX_IMAGE_URL);

      expect(vm.$el.querySelector('.view-modes-menu li.active').textContent.trim()).toBe('2-up');
      expect(vm.$el.querySelector('.view-modes-menu li:nth-child(2)').textContent.trim()).toBe(
        'Swipe',
      );

      expect(vm.$el.querySelector('.view-modes-menu li:nth-child(3)').textContent.trim()).toBe(
        'Onion skin',
      );

      expect(metaInfoElements.length).toBe(2);
      expect(metaInfoElements[0]).toHaveText('2.00 KiB');
      expect(metaInfoElements[1]).toHaveText('1.00 KiB');

      done();
    });
  });

  it('renders image diff for new', (done) => {
    createComponent({ ...allProps, diffMode: 'new', oldPath: '' });

    setImmediate(() => {
      const metaInfoElement = vm.$el.querySelector('.image-info');

      expect(vm.$el.querySelector('.added img').getAttribute('src')).toBe(GREEN_BOX_IMAGE_URL);
      expect(metaInfoElement).toHaveText('1.00 KiB');

      done();
    });
  });

  it('renders image diff for deleted', (done) => {
    createComponent({ ...allProps, diffMode: 'deleted', newPath: '' });

    setImmediate(() => {
      const metaInfoElement = vm.$el.querySelector('.image-info');

      expect(vm.$el.querySelector('.deleted img').getAttribute('src')).toBe(RED_BOX_IMAGE_URL);
      expect(metaInfoElement).toHaveText('2.00 KiB');

      done();
    });
  });

  it('renders image diff for renamed', (done) => {
    vm = new Vue({
      components: {
        imageDiffViewer,
      },
      data() {
        return {
          ...allProps,
          diffMode: 'renamed',
        };
      },
      ...compileToFunctions(`
        <image-diff-viewer
          :diff-mode="diffMode"
          :new-path="newPath"
          :old-path="oldPath"
          :new-size="newSize"
          :old-size="oldSize"
        >
          <template #image-overlay>
            <span class="overlay">test</span>
          </template>
        </image-diff-viewer>
      `),
    }).$mount();

    setImmediate(() => {
      const metaInfoElement = vm.$el.querySelector('.image-info');

      expect(vm.$el.querySelector('img').getAttribute('src')).toBe(GREEN_BOX_IMAGE_URL);
      expect(vm.$el.querySelector('.overlay')).not.toBe(null);

      expect(metaInfoElement).toHaveText('2.00 KiB');

      done();
    });
  });

  describe('swipeMode', () => {
    beforeEach((done) => {
      createComponent({ ...requiredProps });

      setImmediate(() => {
        done();
      });
    });

    it('switches to Swipe Mode', (done) => {
      vm.$el.querySelector('.view-modes-menu li:nth-child(2)').click();

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.view-modes-menu li.active').textContent.trim()).toBe('Swipe');
        done();
      });
    });
  });

  describe('onionSkin', () => {
    beforeEach((done) => {
      createComponent({ ...requiredProps });

      setImmediate(() => {
        done();
      });
    });

    it('switches to Onion Skin Mode', (done) => {
      vm.$el.querySelector('.view-modes-menu li:nth-child(3)').click();

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.view-modes-menu li.active').textContent.trim()).toBe(
          'Onion skin',
        );
        done();
      });
    });

    it('has working drag handler', (done) => {
      vm.$el.querySelector('.view-modes-menu li:nth-child(3)').click();

      vm.$nextTick(() => {
        dragSlider(vm.$el.querySelector('.dragger'), document, 20);

        vm.$nextTick(() => {
          expect(vm.$el.querySelector('.dragger').style.left).toBe('20px');
          expect(vm.$el.querySelector('.added.frame').style.opacity).toBe('0.2');
          done();
        });
      });
    });
  });
});

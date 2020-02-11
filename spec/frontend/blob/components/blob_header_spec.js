import { shallowMount, mount } from '@vue/test-utils';
import BlobHeader from '~/blob/components/blob_header.vue';
import ViewerSwitcher from '~/blob/components/blob_header_viewer_switcher.vue';
import DefaultActions from '~/blob/components/blob_header_default_actions.vue';
import BlobFilepath from '~/blob/components/blob_header_filepath.vue';
import eventHub from '~/blob/event_hub';

import { Blob } from './mock_data';

describe('Blob Header Default Actions', () => {
  let wrapper;

  function createComponent(blobProps = {}, options = {}, propsData = {}, shouldMount = false) {
    const method = shouldMount ? mount : shallowMount;
    wrapper = method.call(this, BlobHeader, {
      propsData: {
        blob: Object.assign({}, Blob, blobProps),
        ...propsData,
      },
      ...options,
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    const slots = {
      prepend: 'Foo Prepend',
      actions: 'Actions Bar',
    };

    it('matches the snapshot', () => {
      createComponent();
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders all components', () => {
      createComponent();
      expect(wrapper.find(ViewerSwitcher).exists()).toBe(true);
      expect(wrapper.find(DefaultActions).exists()).toBe(true);
      expect(wrapper.find(BlobFilepath).exists()).toBe(true);
    });

    it('does not render viewer switcher if the blob has only the simple viewer', () => {
      createComponent({
        richViewer: null,
      });
      expect(wrapper.find(ViewerSwitcher).exists()).toBe(false);
    });

    it('does not render viewer switcher if a corresponding prop is passed', () => {
      createComponent(
        {},
        {},
        {
          hideViewerSwitcher: true,
        },
      );
      expect(wrapper.find(ViewerSwitcher).exists()).toBe(false);
    });

    it('does not render default actions is corresponding prop is passed', () => {
      createComponent(
        {},
        {},
        {
          hideDefaultActions: true,
        },
      );
      expect(wrapper.find(DefaultActions).exists()).toBe(false);
    });

    Object.keys(slots).forEach(slot => {
      it('renders the slots', () => {
        const slotContent = slots[slot];
        createComponent(
          {},
          {
            scopedSlots: {
              [slot]: `<span>${slotContent}</span>`,
            },
          },
          {},
          true,
        );
        expect(wrapper.text()).toContain(slotContent);
      });
    });
  });

  describe('functionality', () => {
    const newViewer = 'Foo Bar';

    it('listens to "switch-view" event when viewer switcher is shown and updates activeViewer', () => {
      expect(wrapper.vm.showViewerSwitcher).toBe(true);
      eventHub.$emit('switch-viewer', newViewer);

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.activeViewer).toBe(newViewer);
      });
    });

    it('does not update active viewer if the switcher is not shown', () => {
      const activeViewer = 'Alpha Beta';
      createComponent(
        {},
        {
          data() {
            return {
              activeViewer,
            };
          },
        },
        {
          hideViewerSwitcher: true,
        },
      );

      expect(wrapper.vm.showViewerSwitcher).toBe(false);
      eventHub.$emit('switch-viewer', newViewer);

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.activeViewer).toBe(activeViewer);
      });
    });
  });
});

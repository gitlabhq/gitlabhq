import { shallowMount, mount } from '@vue/test-utils';
import BlobHeader from '~/blob/components/blob_header.vue';
import ViewerSwitcher from '~/blob/components/blob_header_viewer_switcher.vue';
import DefaultActions from '~/blob/components/blob_header_default_actions.vue';
import BlobFilepath from '~/blob/components/blob_header_filepath.vue';

import { Blob } from './mock_data';

describe('Blob Header Default Actions', () => {
  let wrapper;

  function createComponent(blobProps = {}, options = {}, propsData = {}, shouldMount = false) {
    const method = shouldMount ? mount : shallowMount;
    const blobHash = 'foo-bar';
    wrapper = method.call(this, BlobHeader, {
      provide: {
        blobHash,
      },
      propsData: {
        blob: { ...Blob, ...blobProps },
        ...propsData,
      },
      ...options,
    });
  }

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

    it('passes information about render error down to default actions', () => {
      createComponent(
        {},
        {},
        {
          hasRenderError: true,
        },
      );
      expect(wrapper.find(DefaultActions).props('hasRenderError')).toBe(true);
    });
  });

  describe('functionality', () => {
    const newViewer = 'Foo Bar';
    const activeViewerType = 'Alpha Beta';

    const factory = (hideViewerSwitcher = false) => {
      createComponent(
        {},
        {},
        {
          activeViewerType,
          hideViewerSwitcher,
        },
      );
    };

    it('by default sets viewer data based on activeViewerType', () => {
      factory();
      expect(wrapper.vm.viewer).toBe(activeViewerType);
    });

    it('sets viewer to null if the viewer switcher should be hidden', () => {
      factory(true);
      expect(wrapper.vm.viewer).toBe(null);
    });

    it('watches the changes in viewer data and emits event when the change is registered', () => {
      factory();
      jest.spyOn(wrapper.vm, '$emit');
      wrapper.vm.viewer = newViewer;

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.$emit).toHaveBeenCalledWith('viewer-changed', newViewer);
      });
    });

    it('does not emit event if the switcher is not rendered', () => {
      factory(true);

      expect(wrapper.vm.showViewerSwitcher).toBe(false);
      jest.spyOn(wrapper.vm, '$emit');
      wrapper.vm.viewer = newViewer;

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.$emit).not.toHaveBeenCalled();
      });
    });
  });
});

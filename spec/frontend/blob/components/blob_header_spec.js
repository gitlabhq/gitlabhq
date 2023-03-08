import { shallowMount, mount } from '@vue/test-utils';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import BlobHeader from '~/blob/components/blob_header.vue';
import DefaultActions from '~/blob/components/blob_header_default_actions.vue';
import BlobFilepath from '~/blob/components/blob_header_filepath.vue';
import ViewerSwitcher from '~/blob/components/blob_header_viewer_switcher.vue';
import {
  RICH_BLOB_VIEWER_TITLE,
  SIMPLE_BLOB_VIEWER,
  SIMPLE_BLOB_VIEWER_TITLE,
} from '~/blob/components/constants';
import TableContents from '~/blob/components/table_contents.vue';

import { Blob } from './mock_data';

describe('Blob Header Default Actions', () => {
  let wrapper;

  const defaultProvide = {
    blobHash: 'foo-bar',
  };

  const findDefaultActions = () => wrapper.findComponent(DefaultActions);
  const findTableContents = () => wrapper.findComponent(TableContents);
  const findViewSwitcher = () => wrapper.findComponent(ViewerSwitcher);
  const findBlobFilePath = () => wrapper.findComponent(BlobFilepath);
  const findRichTextEditorBtn = () => wrapper.findByLabelText(RICH_BLOB_VIEWER_TITLE);
  const findSimpleTextEditorBtn = () => wrapper.findByLabelText(SIMPLE_BLOB_VIEWER_TITLE);

  function createComponent({
    blobProps = {},
    options = {},
    propsData = {},
    mountFn = shallowMount,
  } = {}) {
    wrapper = mountFn(BlobHeader, {
      provide: {
        ...defaultProvide,
      },
      propsData: {
        blob: { ...Blob, ...blobProps },
        ...propsData,
      },
      ...options,
    });
  }

  describe('rendering', () => {
    it('matches the snapshot', () => {
      createComponent();
      expect(wrapper.element).toMatchSnapshot();
    });

    describe('default render', () => {
      it.each`
        findComponent         | componentName
        ${findTableContents}  | ${'TableContents'}
        ${findViewSwitcher}   | ${'ViewSwitcher'}
        ${findDefaultActions} | ${'DefaultActions'}
        ${findBlobFilePath}   | ${'BlobFilePath'}
      `('renders $componentName component by default', ({ findComponent }) => {
        createComponent();

        expect(findComponent().exists()).toBe(true);
      });
    });

    it('does not render viewer switcher if the blob has only the simple viewer', () => {
      createComponent({
        blobProps: {
          richViewer: null,
        },
      });
      expect(findViewSwitcher().exists()).toBe(false);
    });

    it('does not render viewer switcher if a corresponding prop is passed', () => {
      createComponent({
        propsData: {
          hideViewerSwitcher: true,
        },
      });
      expect(findViewSwitcher().exists()).toBe(false);
    });

    it('does not render default actions is corresponding prop is passed', () => {
      createComponent({
        propsData: {
          hideDefaultActions: true,
        },
      });
      expect(findDefaultActions().exists()).toBe(false);
    });

    it.each`
      slotContent      | key
      ${'Foo Prepend'} | ${'prepend'}
      ${'Actions Bar'} | ${'actions'}
    `('renders the slot $key', ({ key, slotContent }) => {
      createComponent({
        options: {
          scopedSlots: {
            [key]: `<span>${slotContent}</span>`,
          },
        },
        mountFn: mount,
      });
      expect(wrapper.text()).toContain(slotContent);
    });

    it('passes information about render error down to default actions', () => {
      createComponent({
        propsData: {
          hasRenderError: true,
        },
      });
      expect(findDefaultActions().props('hasRenderError')).toBe(true);
    });

    it('passes the correct isBinary value to default actions when viewing a binary file', () => {
      createComponent({ propsData: { isBinary: true } });

      expect(findDefaultActions().props('isBinary')).toBe(true);
    });
  });

  describe('functionality', () => {
    const factory = (hideViewerSwitcher = false) => {
      createComponent({
        propsData: {
          activeViewerType: SIMPLE_BLOB_VIEWER,
          hideViewerSwitcher,
        },
        mountFn: mountExtended,
      });
    };

    it('shows the correctly selected view by default', () => {
      factory();

      expect(findViewSwitcher().exists()).toBe(true);
      expect(findRichTextEditorBtn().props().selected).toBe(false);
      expect(findSimpleTextEditorBtn().props().selected).toBe(true);
    });

    it('Does not show the viewer switcher should be hidden', () => {
      factory(true);

      expect(findViewSwitcher().exists()).toBe(false);
    });

    it('watches the changes in viewer data and emits event when the change is registered', async () => {
      factory();

      await findRichTextEditorBtn().trigger('click');

      expect(wrapper.emitted('viewer-changed')).toBeDefined();
    });

    it('sets different icons depending on the blob file type', async () => {
      factory();

      expect(findViewSwitcher().props('docIcon')).toBe('document');

      await wrapper.setProps({
        blob: {
          ...Blob,
          richViewer: {
            ...Blob.richViewer,
            fileType: 'csv',
          },
        },
      });

      expect(findViewSwitcher().props('docIcon')).toBe('table');
    });
  });
});

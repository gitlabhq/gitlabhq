import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlobHeader from '~/blob/components/blob_header.vue';
import DefaultActions from '~/blob/components/blob_header_default_actions.vue';
import BlobFilepath from '~/blob/components/blob_header_filepath.vue';
import ViewerSwitcher from '~/blob/components/blob_header_viewer_switcher.vue';
import { SIMPLE_BLOB_VIEWER } from '~/blob/components/constants';
import TableContents from '~/blob/components/table_contents.vue';
import waitForPromises from 'helpers/wait_for_promises';
import WebIdeLink from 'ee_else_ce/vue_shared/components/web_ide_link.vue';
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
  const findRichTextEditorBtn = () => wrapper.findByTestId('rich-blob-viewer-button');
  const findSimpleTextEditorBtn = () => wrapper.findByTestId('simple-blob-viewer-button');
  const findDuoWorkflowActionSlot = () => wrapper.findByTestId('ee-duo-workflow-action');

  async function createComponent({
    blobProps = {},
    options = {},
    propsData = {},
    mountFn = shallowMountExtended,
  } = {}) {
    wrapper = mountFn(BlobHeader, {
      provide: {
        ...defaultProvide,
      },
      propsData: {
        blob: { ...Blob, ...blobProps },
        ...propsData,
      },
      stubs: {
        WebIdeLink,
      },
      ...options,
    });

    await waitForPromises();
  }

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('default render', () => {
      it.each`
        findComponent        | componentName
        ${findTableContents} | ${'TableContents'}
        ${findViewSwitcher}  | ${'ViewSwitcher'}
        ${findBlobFilePath}  | ${'BlobFilePath'}
      `('renders $componentName component by default', ({ findComponent }) => {
        expect(findComponent().exists()).toBe(true);
      });
    });

    describe('DefaultActions component', () => {
      it('renders DefaultActions', () => {
        expect(findDefaultActions().exists()).toBe(true);
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

    it.each([[{ showBlameToggle: true }], [{ showBlameToggle: false }]])(
      'passes the `showBlameToggle` prop to the viewer switcher',
      (propsData) => {
        createComponent({ propsData });

        expect(findViewSwitcher().props('showBlameToggle')).toBe(propsData.showBlameToggle);
      },
    );

    it('does not render viewer switcher if the blob has only the simple viewer', () => {
      createComponent({
        blobProps: {
          richViewer: null,
        },
      });
      expect(findViewSwitcher().props('showViewerToggles')).toBe(false);
    });

    it('does not render viewer switcher if a corresponding prop is passed', () => {
      createComponent({
        propsData: {
          hideViewerSwitcher: true,
        },
      });
      expect(findViewSwitcher().exists()).toBe(false);
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
        mountFn: mountExtended,
      });
      expect(wrapper.text()).toContain(slotContent);
    });

    it('passes the `showBlobSize` prop to `blobFilepath`', () => {
      const showBlobSize = false;
      createComponent({ propsData: { showBlobSize } });
      expect(findBlobFilePath().props('showBlobSize')).toBe(showBlobSize);
    });

    it('does not render the Duo Workflow action slot', () => {
      expect(findDuoWorkflowActionSlot().exists()).toBe(false);
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
  });
});

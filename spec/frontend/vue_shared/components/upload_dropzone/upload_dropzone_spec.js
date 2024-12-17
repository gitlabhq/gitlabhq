import { GlAnimatedUploadIcon, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { VALID_DESIGN_FILE_MIMETYPE } from '~/work_items/components/design_management/constants';

describe('Upload dropzone component', () => {
  let wrapper;

  const mockDragEvent = ({ types = ['Files'], files = [], items = [] }) => {
    return { dataTransfer: { types, files, items } };
  };

  const findDropzoneCard = () => wrapper.find('.upload-dropzone-card');
  const findDropzoneArea = () => wrapper.findByTestId('dropzone-area');
  const findIcon = () => wrapper.findComponent(GlAnimatedUploadIcon);
  const findUploadText = () => wrapper.findByTestId('upload-text').text();
  const findFileInput = () => wrapper.find('input[type="file"]');

  function createComponent({ slots = {}, props = {} } = {}) {
    wrapper = shallowMountExtended(UploadDropzone, {
      slots,
      propsData: {
        displayAsCard: true,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  }

  describe('when slot provided', () => {
    it('renders dropzone with slot content', () => {
      createComponent({
        slots: {
          default: ['<div>dropzone slot</div>'],
        },
      });

      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('when no slot provided', () => {
    it('renders default dropzone card', () => {
      createComponent();

      expect(wrapper.element).toMatchSnapshot();
    });

    it('triggers click event on file input element when clicked', () => {
      createComponent();
      const clickSpy = jest.spyOn(wrapper.find('input').element, 'click');

      findDropzoneCard().trigger('click');
      expect(clickSpy).toHaveBeenCalled();
    });
  });

  describe('upload text', () => {
    it.each`
      collection    | description                   | props                            | expected
      ${'multiple'} | ${'by default'}               | ${null}                          | ${'files to attach'}
      ${'singular'} | ${'when singleFileSelection'} | ${{ singleFileSelection: true }} | ${'file to attach'}
    `('displays $collection version $description', ({ props, expected }) => {
      createComponent({ props });

      expect(findUploadText()).toContain(expected);
    });
  });

  describe('when dragging', () => {
    it.each`
      description                  | eventPayload
      ${'is empty'}                | ${{}}
      ${'contains text'}           | ${mockDragEvent({ types: ['text'] })}
      ${'contains files and text'} | ${mockDragEvent({ types: ['Files', 'text'] })}
      ${'contains files'}          | ${mockDragEvent({ types: ['Files'] })}
    `('renders correct template when drag event $description', async ({ eventPayload }) => {
      createComponent();

      wrapper.trigger('dragenter', eventPayload);
      await nextTick();
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders correct template when dragging stops', async () => {
      createComponent();

      wrapper.trigger('dragenter');

      await nextTick();
      wrapper.trigger('dragleave');

      await nextTick();
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('when dragging with design upload overlay enabled', () => {
    const findDesignUploadOverlay = () => wrapper.findByTestId('design-upload-overlay');
    const triggerDragEvents = async (dragEvent) => {
      wrapper.trigger('dragenter', dragEvent);
      await nextTick();

      wrapper.trigger('dragover', dragEvent);
      await nextTick();
    };

    beforeEach(() => {
      createComponent({
        props: {
          showUploadDesignOverlay: true,
          validateDesignUploadOnDragover: true,
          uploadDesignOverlayText: 'Drop your images to start the upload.',
          acceptDesignFormats: VALID_DESIGN_FILE_MIMETYPE.mimetype,
        },
      });
    });

    it('renders component with requires classes when design upload overlay is true', async () => {
      const dragEvent = mockDragEvent({
        types: ['Files', 'image'],
        items: [{ type: 'image/png' }],
      });

      await triggerDragEvents(dragEvent);

      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders design upload overlay with text on drag of valid design', async () => {
      const dragEvent = mockDragEvent({
        types: ['Files', 'image'],
        items: [{ type: 'image/png' }],
      });

      await triggerDragEvents(dragEvent);

      const designUploadOverlay = findDesignUploadOverlay();
      expect(designUploadOverlay.exists()).toBe(true);
      expect(designUploadOverlay.isVisible()).toBe(true);
      expect(designUploadOverlay.findComponent(GlAnimatedUploadIcon).exists()).toBe(true);
      expect(designUploadOverlay.text()).toBe('Drop your images to start the upload.');
    });

    it('does not render design upload overlay on drag of invalid design', async () => {
      const dragEvent = mockDragEvent({
        types: ['Files', 'video'],
        items: [{ type: 'video/quicktime' }],
      });

      await triggerDragEvents(dragEvent);

      const designUploadOverlay = findDesignUploadOverlay();
      expect(designUploadOverlay.exists()).toBe(false);
    });
  });

  describe('when dropping', () => {
    it('emits upload event', async () => {
      createComponent();
      const mockFile = { name: 'test', type: 'image/jpg' };
      const mockEvent = mockDragEvent({ files: [mockFile] });

      wrapper.trigger('dragenter', mockEvent);

      await nextTick();
      wrapper.trigger('drop', mockEvent);

      await nextTick();
      expect(wrapper.emitted('change')).toEqual([[[mockFile]]]);
    });
  });

  describe('ondrop', () => {
    describe('when drag data is valid', () => {
      it('emits upload event for valid files', () => {
        createComponent();

        const mockFile = { type: 'image/jpg' };
        const mockEvent = mockDragEvent({ files: [mockFile] });

        wrapper.trigger('drop', mockEvent);
        expect(wrapper.emitted('change')).toEqual([[[mockFile]]]);
      });

      it('emits error event when files are invalid', () => {
        createComponent();
        const mockEvent = mockDragEvent({ files: [{ type: 'audio/midi' }] });

        wrapper.trigger('drop', mockEvent);
        expect(wrapper.emitted()).toHaveProperty('error');
      });

      it('allows validation function to be overwritten', () => {
        createComponent({ props: { isFileValid: () => true } });

        const mockEvent = mockDragEvent({ files: [{ type: 'audio/midi' }] });

        wrapper.trigger('drop', mockEvent);
        expect(wrapper.emitted()).not.toHaveProperty('error');
      });

      describe('singleFileSelection = true', () => {
        it('emits a single file on drop', () => {
          createComponent({
            props: { singleFileSelection: true },
          });

          const mockFile = { type: 'image/jpg' };
          const mockEvent = mockDragEvent({ files: [mockFile] });

          wrapper.trigger('drop', mockEvent);
          expect(wrapper.emitted('change')).toEqual([[mockFile]]);
        });
      });
    });
  });

  it('applies correct classes when displaying as a standalone item', () => {
    createComponent({ props: { displayAsCard: false } });
    expect(findDropzoneArea().classes()).not.toContain('gl-flex-col');
    expect(findIcon().classes()).toEqual(['gl-mr-3']);
  });

  it('applies correct classes when displaying in card mode', () => {
    createComponent({ props: { displayAsCard: true } });
    expect(findDropzoneArea().classes()).toContain('gl-flex-col');
    expect(findIcon().classes()).toEqual(['gl-mb-3']);
  });

  it('animates icon on hover', async () => {
    createComponent();

    findDropzoneCard().trigger('mouseenter');
    await nextTick();

    expect(findIcon().props('isOn')).toEqual(true);
  });

  it('does not animate icon on mouse leave', async () => {
    createComponent();

    findDropzoneCard().trigger('mouseleave');
    await nextTick();

    expect(findIcon().props('isOn')).toEqual(false);
  });

  it('correctly overrides description and drop messages', () => {
    createComponent({
      props: {
        dropToStartMessage: 'Test drop-to-start message.',
        validFileMimetypes: ['image/jpg', 'image/jpeg'],
      },
      slots: {
        'upload-text': '<span>Test %{linkStart}description%{linkEnd} message.</span>',
      },
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('correctly overrides single upload messages', () => {
    createComponent({
      props: {
        singleFileSelection: true,
        uploadSingleMessage: 'Drop or select file to attach',
      },
    });
    expect(findUploadText()).toContain('Drop or select file to attach');
  });

  it('correctly overrides multiple upload messages', () => {
    createComponent({
      props: {
        singleFileSelection: false,
        uploadMultipleMessage: 'Drop or select files to attach',
      },
    });

    expect(findUploadText()).toContain('Drop or select files to attach');
  });

  describe('file input form name', () => {
    it('applies inputFieldName as file input name', () => {
      createComponent({ props: { inputFieldName: 'test_field_name' } });
      expect(findFileInput().attributes('name')).toBe('test_field_name');
    });

    it('uses default file input name if no inputFieldName provided', () => {
      createComponent();
      expect(findFileInput().attributes('name')).toBe('upload_file');
    });
  });

  describe('updates file input files value', () => {
    // NOTE: the component assigns dropped files from the drop event to the
    // input.files property. There's a restriction that nothing but a FileList
    // can be assigned to this property. While FileList can't be created
    // manually: it has no constructor. And currently there's no good workaround
    // for jsdom. So we have to stub the file input in vm.$refs to ensure that
    // the files property is updated. This enforces following tests to know a
    // bit too much about the SUT internals See this thread for more details on
    // FileList in jsdom: https://github.com/jsdom/jsdom/issues/1272
    function stubFileInputOnWrapper() {
      const fakeFileInput = { files: [] };
      wrapper.vm.$refs.fileUpload = fakeFileInput;
    }

    it('assigns dragged files to the input files property', async () => {
      const mockFile = { name: 'test', type: 'image/jpg' };
      const mockEvent = mockDragEvent({ files: [mockFile] });
      createComponent({ props: { shouldUpdateInputOnFileDrop: true } });
      stubFileInputOnWrapper();

      wrapper.trigger('dragenter', mockEvent);
      await nextTick();
      wrapper.trigger('drop', mockEvent);
      await nextTick();

      expect(wrapper.vm.$refs.fileUpload.files).toEqual([mockFile]);
    });

    it('throws an error when multiple files are dropped on a single file input dropzone', async () => {
      const mockFile = { name: 'test', type: 'image/jpg' };
      const mockEvent = mockDragEvent({ files: [mockFile, mockFile] });
      createComponent({ props: { shouldUpdateInputOnFileDrop: true, singleFileSelection: true } });
      stubFileInputOnWrapper();

      wrapper.trigger('dragenter', mockEvent);
      await nextTick();
      wrapper.trigger('drop', mockEvent);
      await nextTick();

      expect(wrapper.vm.$refs.fileUpload.files).toEqual([]);
      expect(wrapper.emitted('error')).toHaveLength(1);
    });
  });
});

import { GlIcon, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';

jest.mock('~/flash');

describe('Upload dropzone component', () => {
  let wrapper;

  const mockDragEvent = ({ types = ['Files'], files = [] }) => {
    return { dataTransfer: { types, files } };
  };

  const findDropzoneCard = () => wrapper.find('.upload-dropzone-card');
  const findDropzoneArea = () => wrapper.find('[data-testid="dropzone-area"]');
  const findIcon = () => wrapper.find(GlIcon);
  const findUploadText = () => wrapper.find('[data-testid="upload-text"]').text();

  function createComponent({ slots = {}, data = {}, props = {} } = {}) {
    wrapper = shallowMount(UploadDropzone, {
      slots,
      propsData: {
        displayAsCard: true,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
      data() {
        return data;
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

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
    `('renders correct template when drag event $description', ({ eventPayload }) => {
      createComponent();

      wrapper.trigger('dragenter', eventPayload);
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.element).toMatchSnapshot();
      });
    });

    it('renders correct template when dragging stops', () => {
      createComponent();

      wrapper.trigger('dragenter');
      return wrapper.vm
        .$nextTick()
        .then(() => {
          wrapper.trigger('dragleave');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(wrapper.element).toMatchSnapshot();
        });
    });
  });

  describe('when dropping', () => {
    it('emits upload event', () => {
      createComponent();
      const mockFile = { name: 'test', type: 'image/jpg' };
      const mockEvent = mockDragEvent({ files: [mockFile] });

      wrapper.trigger('dragenter', mockEvent);
      return wrapper.vm
        .$nextTick()
        .then(() => {
          wrapper.trigger('drop', mockEvent);
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(wrapper.emitted().change[0]).toEqual([[mockFile]]);
        });
    });
  });

  describe('ondrop', () => {
    const mockData = { dragCounter: 1, isDragDataValid: true };

    describe('when drag data is valid', () => {
      it('emits upload event for valid files', () => {
        createComponent({ data: mockData });

        const mockFile = { type: 'image/jpg' };
        const mockEvent = mockDragEvent({ files: [mockFile] });

        wrapper.vm.ondrop(mockEvent);
        expect(wrapper.emitted().change[0]).toEqual([[mockFile]]);
      });

      it('emits error event when files are invalid', () => {
        createComponent({ data: mockData });
        const mockEvent = mockDragEvent({ files: [{ type: 'audio/midi' }] });

        wrapper.vm.ondrop(mockEvent);
        expect(wrapper.emitted()).toHaveProperty('error');
      });

      it('allows validation function to be overwritten', () => {
        createComponent({ data: mockData, props: { isFileValid: () => true } });

        const mockEvent = mockDragEvent({ files: [{ type: 'audio/midi' }] });

        wrapper.vm.ondrop(mockEvent);
        expect(wrapper.emitted()).not.toHaveProperty('error');
      });

      describe('singleFileSelection = true', () => {
        it('emits a single file on drop', () => {
          createComponent({
            data: mockData,
            props: { singleFileSelection: true },
          });

          const mockFile = { type: 'image/jpg' };
          const mockEvent = mockDragEvent({ files: [mockFile] });

          wrapper.vm.ondrop(mockEvent);
          expect(wrapper.emitted().change[0]).toEqual([mockFile]);
        });
      });
    });
  });

  it('applies correct classes when displaying as a standalone item', () => {
    createComponent({ props: { displayAsCard: false } });
    expect(findDropzoneArea().classes()).not.toContain('gl-flex-direction-column');
    expect(findIcon().classes()).toEqual(['gl-mr-3', 'gl-text-gray-500']);
    expect(findIcon().props('size')).toBe(16);
  });

  it('applies correct classes when displaying in card mode', () => {
    createComponent({ props: { displayAsCard: true } });
    expect(findDropzoneArea().classes()).toContain('gl-flex-direction-column');
    expect(findIcon().classes()).toEqual(['gl-mb-2']);
    expect(findIcon().props('size')).toBe(24);
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
});

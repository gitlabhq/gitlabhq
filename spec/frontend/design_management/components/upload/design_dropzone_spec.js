import { shallowMount } from '@vue/test-utils';
import DesignDropzone from '~/design_management/components/upload/design_dropzone.vue';
import createFlash from '~/flash';

jest.mock('~/flash');

describe('Design management dropzone component', () => {
  let wrapper;

  const mockDragEvent = ({ types = ['Files'], files = [] }) => {
    return { dataTransfer: { types, files } };
  };

  const findDropzoneCard = () => wrapper.find('.design-dropzone-card');

  function createComponent({ slots = {}, data = {} } = {}) {
    wrapper = shallowMount(DesignDropzone, {
      slots,
      data() {
        return data;
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
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

      it('calls createFlash when files are invalid', () => {
        createComponent({ data: mockData });

        const mockEvent = mockDragEvent({ files: [{ type: 'audio/midi' }] });

        wrapper.vm.ondrop(mockEvent);
        expect(createFlash).toHaveBeenCalledTimes(1);
      });
    });
  });
});

import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import UploadButton from '~/projects/details/upload_button.vue';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';

const MODAL_ID = 'details-modal-upload-blob';

describe('UploadButton', () => {
  let wrapper;
  let glModalDirective;

  const createComponent = () => {
    glModalDirective = jest.fn();

    return shallowMount(UploadButton, {
      directives: {
        glModal: {
          bind(_, { value }) {
            glModalDirective(value);
          },
        },
      },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('displays an upload button', () => {
    expect(wrapper.findComponent(GlButton).exists()).toBe(true);
  });

  it('contains a modal', () => {
    const modal = wrapper.findComponent(UploadBlobModal);

    expect(modal.exists()).toBe(true);
    expect(modal.props('modalId')).toBe(MODAL_ID);
  });

  describe('when clickinig the upload file button', () => {
    beforeEach(() => {
      wrapper.findComponent(GlButton).vm.$emit('click');
    });

    it('opens the modal', () => {
      expect(glModalDirective).toHaveBeenCalledWith(MODAL_ID);
    });
  });
});

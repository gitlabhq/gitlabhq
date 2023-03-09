import { shallowMount } from '@vue/test-utils';
import NoteAttachment from '~/notes/components/note_attachment.vue';

describe('Issue note attachment', () => {
  let wrapper;

  const findImage = () => wrapper.findComponent({ ref: 'attachmentImage' });
  const findUrl = () => wrapper.findComponent({ ref: 'attachmentUrl' });

  const createComponent = (attachment) => {
    wrapper = shallowMount(NoteAttachment, {
      propsData: {
        attachment,
      },
    });
  };

  it('renders attachment image if it is passed in attachment prop', () => {
    createComponent({
      image: 'test-image',
    });

    expect(findImage().exists()).toBe(true);
  });

  it('renders attachment url if it is passed in attachment prop', () => {
    createComponent({
      url: 'test-url',
    });

    expect(findUrl().exists()).toBe(true);
  });

  it('does not render image and url if attachment object is empty', () => {
    createComponent({});

    expect(findImage().exists()).toBe(false);
    expect(findUrl().exists()).toBe(false);
  });
});

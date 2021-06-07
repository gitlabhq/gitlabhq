import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import InsertVideoModal from '~/static_site_editor/rich_content_editor/modals/insert_video_modal.vue';

describe('Insert Video Modal', () => {
  let wrapper;

  const findModal = () => wrapper.find(GlModal);
  const findUrlInput = () => wrapper.find({ ref: 'urlInput' });

  const triggerInsertVideo = (url) => {
    const preventDefault = jest.fn();
    findUrlInput().vm.$emit('input', url);
    findModal().vm.$emit('primary', { preventDefault });
  };

  beforeEach(() => {
    wrapper = shallowMount(InsertVideoModal);
  });

  afterEach(() => wrapper.destroy());

  describe('when content is loaded', () => {
    it('renders a modal component', () => {
      expect(findModal().exists()).toBe(true);
    });

    it('renders an input to add a URL', () => {
      expect(findUrlInput().exists()).toBe(true);
    });
  });

  describe('insert video', () => {
    it.each`
      url                                       | emitted
      ${'https://www.youtube.com/embed/someId'} | ${[['https://www.youtube.com/embed/someId']]}
      ${'https://www.youtube.com/watch?v=1234'} | ${[['https://www.youtube.com/embed/1234']]}
      ${'::youtube.com/invalid/url'}            | ${undefined}
    `('formats the url correctly', ({ url, emitted }) => {
      triggerInsertVideo(url);
      expect(wrapper.emitted('insertVideo')).toEqual(emitted);
    });
  });
});

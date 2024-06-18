import { GlLink } from '@gitlab/ui';
import { NodeViewWrapper } from '@tiptap/vue-2';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PlayableWrapper from '~/content_editor/components/wrappers/playable.vue';

jest.mock('~/content_editor/services/upload_helpers', () => ({
  uploadingStates: {
    audio12: true,
    video12: true,
  },
}));

describe('content/components/wrappers/playable_spec', () => {
  let wrapper;

  const createWrapper = (node = {}) => {
    wrapper = shallowMountExtended(PlayableWrapper, {
      propsData: {
        node,
      },
    });
  };

  const findMedia = (type) => wrapper.find(`[as="${type}"]`);

  describe.each`
    type       | src            | alt           | title
    ${'video'} | ${'video.mp4'} | ${'My Video'} | ${'My Video 1'}
    ${'audio'} | ${'audio.mp3'} | ${'My Audio'} | ${'My Audio 1'}
  `('for mediaType=$type', ({ type, src, alt, title }) => {
    beforeEach(() => {
      createWrapper({ type: { name: type }, attrs: { src, alt, title } });
    });

    it(`renders a ${type} element with the given attributes`, () => {
      expect(findMedia(type).attributes()).toMatchObject({ src, 'data-title': title });
    });

    it('renders alt as title if title is not provided', () => {
      createWrapper({ type: { name: type }, attrs: { src, alt } });

      expect(findMedia(type).attributes('data-title')).toEqual(alt);
    });

    it(`marks the ${type} element as draggable`, () => {
      expect(findMedia(type).attributes()).toMatchObject({
        draggable: 'true',
        'data-drag-handle': '',
      });
    });

    it(`renders a gl-link with the link to the ${type}`, () => {
      expect(wrapper.findComponent(GlLink).attributes()).toMatchObject({
        class: 'with-attachment-icon',
        href: src,
        target: '_blank',
      });
    });

    it('marks the gl-link as draggable', () => {
      expect(wrapper.findComponent(GlLink).attributes()).toMatchObject({
        draggable: 'true',
        'data-drag-handle': '',
      });
    });

    it('hides the wrapper component if it is a stale upload', () => {
      createWrapper({
        type: { name: type },
        attrs: { src, alt, uploading: `${type}12` },
      });

      expect(wrapper.findComponent(NodeViewWrapper).attributes('style')).toBe('display: none;');
    });

    it('does not hide the wrapper component if the upload is not stale', () => {
      createWrapper({
        type: { name: type },
        attrs: { src, alt, uploading: `${type}13` },
      });

      expect(wrapper.findComponent(NodeViewWrapper).attributes('style')).toBeUndefined();
    });
  });
});

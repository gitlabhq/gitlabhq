import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import ImageDiffOverlay from '~/diffs/components/image_diff_overlay.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';
import { imageDiffDiscussions } from '../mock_data/diff_discussions';

Vue.use(PiniaVuePlugin);

describe('Diffs image diff overlay component', () => {
  const dimensions = {
    width: 99.9,
    height: 199.5,
  };

  let wrapper;
  let pinia;

  const getAllImageBadges = () => wrapper.findAllComponents(DesignNotePin);

  function createComponent(props = {}) {
    wrapper = shallowMount(ImageDiffOverlay, {
      pinia,
      parentComponent: {
        data() {
          return dimensions;
        },
      },
      propsData: {
        discussions: [...imageDiffDiscussions],
        fileHash: 'ABC',
        renderedWidth: 200,
        renderedHeight: 200,
        ...props,
      },
    });
    // Vue 3 doesn't stub parent component's state with data()
    if (!wrapper.vm.$parent.width) {
      wrapper.vm.$parent.width = dimensions.width;
      wrapper.vm.$parent.height = dimensions.height;
    }
  }

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
  });

  it('renders comment badges', () => {
    createComponent();

    expect(getAllImageBadges()).toHaveLength(2);
  });

  it('renders index of discussion in badge', () => {
    createComponent();
    const imageBadges = getAllImageBadges();

    expect(imageBadges.at(0).props('label')).toBe(1);
    expect(imageBadges.at(1).props('label')).toBe(2);
  });

  it('sets empty label when showCommentIcon is true', () => {
    createComponent({ showCommentIcon: true });

    expect(getAllImageBadges().at(0).props('label')).toBe(null);
  });

  it('sets badge comment positions', () => {
    createComponent();
    const imageBadges = getAllImageBadges();

    expect(imageBadges.at(0).props('position')).toStrictEqual({ left: '10%', top: '5%' });
    expect(imageBadges.at(1).props('position')).toStrictEqual({ left: '5%', top: '2.5%' });
  });

  it('renders single badge for discussion object', () => {
    createComponent({
      discussions: {
        ...imageDiffDiscussions[0],
      },
    });

    expect(getAllImageBadges()).toHaveLength(1);
  });

  it('dispatches openDiffFileCommentForm when clicking overlay', () => {
    createComponent({ canComment: true });
    wrapper.find('.js-add-image-diff-note-button').trigger('click', { offsetX: 1.2, offsetY: 3.8 });

    expect(useLegacyDiffs().openDiffFileCommentForm).toHaveBeenCalledWith({
      fileHash: 'ABC',
      x: 1,
      y: 4,
      width: 100,
      height: 200,
      xPercent: expect.closeTo(0.6),
      yPercent: expect.closeTo(1.9),
    });
  });

  describe('toggle discussion', () => {
    it('disables buttons when shouldToggleDiscussion is false', () => {
      createComponent({ shouldToggleDiscussion: false });

      // Vue 3 sets disabled="disabled", Vue 2 disabled="true"
      expect(['true', 'disabled']).toContain(getAllImageBadges().at(0).attributes('disabled'));
    });

    it('dispatches toggleDiscussion when clicking image badge', () => {
      createComponent();
      getAllImageBadges().at(0).vm.$emit('click');

      expect(useLegacyDiffs().toggleFileDiscussion).toHaveBeenCalledWith({
        id: '1',
        position: {
          height: 200,
          width: 100,
          x: 10,
          y: 10,
        },
      });
    });
  });

  describe('comment form', () => {
    beforeEach(() => {
      useLegacyDiffs().commentForms.push({
        fileHash: 'ABC',
        x: 20,
        y: 10,
        xPercent: 10,
        yPercent: 10,
      });
      createComponent({ canComment: true });
    });

    it('renders comment form badge', () => {
      expect(getAllImageBadges().at(2).exists()).toBe(true);
    });

    it('sets comment form badge position', () => {
      expect(getAllImageBadges().at(2).props('position')).toStrictEqual({
        left: '10%',
        top: '10%',
      });
    });
  });
});

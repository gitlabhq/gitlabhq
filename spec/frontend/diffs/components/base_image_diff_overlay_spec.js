import { shallowMount } from '@vue/test-utils';
import BasaeImageDiffOverlay from '~/diffs/components/base_image_diff_overlay.vue';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';
import { imageDiffDiscussions } from '../mock_data/diff_discussions';

describe('BaseImageDiffOverlay', () => {
  const dimensions = {
    width: 99.9,
    height: 199.5,
  };

  let wrapper;

  const getAllImageBadges = () => wrapper.findAllComponents(DesignNotePin);

  function createComponent(props = {}) {
    wrapper = shallowMount(BasaeImageDiffOverlay, {
      propsData: {
        discussions: [...imageDiffDiscussions],
        fileHash: 'ABC',
        renderedWidth: 200,
        renderedHeight: 200,
        ...dimensions,
        ...props,
      },
    });
  }

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

  it('emits "image-click" event', () => {
    createComponent({ canComment: true });
    wrapper.find('.js-add-image-diff-note-button').trigger('click', { offsetX: 1.2, offsetY: 3.8 });
    expect(wrapper.emitted('image-click')).toStrictEqual([
      [
        {
          x: 1,
          y: 4,
          width: 100,
          height: 200,
          xPercent: expect.closeTo(0.6),
          yPercent: expect.closeTo(1.9),
        },
      ],
    ]);
  });

  describe('toggle discussion', () => {
    it('disables buttons when shouldToggleDiscussion is false', () => {
      createComponent({ shouldToggleDiscussion: false });
      expect(getAllImageBadges().at(0).attributes('disabled')).toBeDefined();
    });

    it('emits "pin-click" event', () => {
      createComponent();
      getAllImageBadges().at(0).vm.$emit('click');

      expect(wrapper.emitted('pin-click')).toStrictEqual([
        [
          {
            id: '1',
            position: {
              height: 200,
              width: 100,
              x: 10,
              y: 10,
            },
          },
        ],
      ]);
    });
  });

  describe('comment form', () => {
    beforeEach(() => {
      createComponent({
        canComment: true,
        commentForm: {
          fileHash: 'ABC',
          x: 20,
          y: 10,
          xPercent: 10,
          yPercent: 10,
        },
      });
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

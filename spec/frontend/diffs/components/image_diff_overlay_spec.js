import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import ImageDiffOverlay from '~/diffs/components/image_diff_overlay.vue';
import { createStore } from '~/mr_notes/stores';
import { imageDiffDiscussions } from '../mock_data/diff_discussions';

describe('Diffs image diff overlay component', () => {
  const dimensions = {
    width: 100,
    height: 200,
  };
  let wrapper;
  let dispatch;
  const getAllImageBadges = () => wrapper.findAll('.js-image-badge');

  function createComponent(props = {}, extendStore = () => {}) {
    const store = createStore();

    extendStore(store);
    dispatch = jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(ImageDiffOverlay, {
      store,
      propsData: {
        discussions: [...imageDiffDiscussions],
        fileHash: 'ABC',
        ...props,
      },
      methods: {
        getImageDimensions: jest.fn().mockReturnValue(dimensions),
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders comment badges', () => {
    createComponent();

    expect(getAllImageBadges()).toHaveLength(2);
  });

  it('renders index of discussion in badge', () => {
    createComponent();
    const imageBadges = getAllImageBadges();

    expect(
      imageBadges
        .at(0)
        .text()
        .trim(),
    ).toBe('1');
    expect(
      imageBadges
        .at(1)
        .text()
        .trim(),
    ).toBe('2');
  });

  it('renders icon when showCommentIcon is true', () => {
    createComponent({ showCommentIcon: true });

    expect(wrapper.find(GlIcon).exists()).toBe(true);
  });

  it('sets badge comment positions', () => {
    createComponent();
    const imageBadges = getAllImageBadges();

    expect(imageBadges.at(0).attributes('style')).toBe('left: 10px; top: 10px;');
    expect(imageBadges.at(1).attributes('style')).toBe('left: 5px; top: 5px;');
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
    wrapper.find('.js-add-image-diff-note-button').trigger('click', { offsetX: 0, offsetY: 0 });

    expect(dispatch).toHaveBeenCalledWith('diffs/openDiffFileCommentForm', {
      fileHash: 'ABC',
      x: 0,
      y: 0,
      width: 100,
      height: 200,
    });
  });

  describe('toggle discussion', () => {
    const getImageBadge = () => wrapper.find('.js-image-badge');

    it('disables buttons when shouldToggleDiscussion is false', () => {
      createComponent({ shouldToggleDiscussion: false });

      expect(getImageBadge().attributes('disabled')).toEqual('disabled');
    });

    it('dispatches toggleDiscussion when clicking image badge', () => {
      createComponent();
      getImageBadge().trigger('click');

      expect(dispatch).toHaveBeenCalledWith('toggleDiscussion', {
        discussionId: '1',
      });
    });
  });

  describe('comment form', () => {
    const getCommentIndicator = () => wrapper.find('.comment-indicator');
    beforeEach(() => {
      createComponent({}, store => {
        store.state.diffs.commentForms.push({
          fileHash: 'ABC',
          x: 20,
          y: 10,
        });
      });
    });

    it('renders comment form badge', () => {
      expect(getCommentIndicator().exists()).toBe(true);
    });

    it('sets comment form badge position', () => {
      expect(getCommentIndicator().attributes('style')).toBe('left: 20px; top: 10px;');
    });
  });
});

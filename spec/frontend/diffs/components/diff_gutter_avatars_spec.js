import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DiffGutterAvatars from '~/diffs/components/diff_gutter_avatars.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import { HIDE_COMMENTS } from '~/diffs/i18n';
import discussionsMockData from '../mock_data/diff_discussions';

const getDiscussionsMockData = () => [{ ...discussionsMockData }];

describe('DiffGutterAvatars', () => {
  let wrapper;

  const findCollapseButton = () => wrapper.find('.diff-notes-collapse');
  const findMoreCount = () => wrapper.find('.diff-comments-more-count');
  const findUserAvatars = () => wrapper.findAllComponents(UserAvatarImage);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DiffGutterAvatars, {
      propsData: {
        ...props,
      },
    });
  };

  describe('when expanded', () => {
    beforeEach(() => {
      createComponent({
        discussions: getDiscussionsMockData(),
        discussionsExpanded: true,
      });
    });

    it('renders a collapse button when discussions are expanded', () => {
      expect(findCollapseButton().exists()).toBe(true);
    });

    it('should emit toggleDiscussions event on button click', async () => {
      findCollapseButton().trigger('click');

      await nextTick();
      expect(wrapper.emitted().toggleLineDiscussions).toBeDefined();
    });

    it('renders the proper title and aria-label', () => {
      expect(findCollapseButton().attributes('title')).toBe(HIDE_COMMENTS);
      expect(findCollapseButton().attributes('aria-label')).toBe(HIDE_COMMENTS);
    });
  });

  describe('when collapsed', () => {
    beforeEach(() => {
      createComponent({
        discussions: getDiscussionsMockData(),
        discussionsExpanded: false,
      });
    });

    it('renders user avatars and moreCount text', () => {
      expect(findUserAvatars().exists()).toBe(true);
      expect(findMoreCount().exists()).toBe(true);
    });

    it('renders correct amount of user avatars', () => {
      expect(findUserAvatars().length).toBe(3);
    });

    // Avoid images in file contents copy: https://gitlab.com/gitlab-org/gitlab/-/issues/337139
    it('renders pseudo avatars', () => {
      expect(findUserAvatars().wrappers.every((avatar) => avatar.props('pseudo'))).toBe(true);
    });

    it('renders correct moreCount number', () => {
      expect(findMoreCount().text()).toBe('+2');
    });

    it('should emit toggleDiscussions event on avatars click', async () => {
      findUserAvatars().at(0).trigger('click');

      await nextTick();
      expect(wrapper.emitted().toggleLineDiscussions).toBeDefined();
    });

    it('should emit toggleDiscussions event on more count text click', async () => {
      findMoreCount().trigger('click');

      await nextTick();
      expect(wrapper.emitted().toggleLineDiscussions).toBeDefined();
    });
  });

  it('renders an empty more count string if there are no discussions', () => {
    createComponent({
      discussions: [],
      discussionsExpanded: false,
    });

    expect(findMoreCount().exists()).toBe(false);
  });

  describe('tooltip text', () => {
    beforeEach(() => {
      createComponent({
        discussions: getDiscussionsMockData(),
        discussionsExpanded: false,
      });
    });

    it('returns original comment if it is shorter than max length', () => {
      const note = wrapper.vm.discussions[0].notes[0];

      expect(wrapper.vm.getTooltipText(note)).toEqual('Administrator: comment 1');
    });

    it('returns truncated version of comment if it is longer than max length', () => {
      const note = wrapper.vm.discussions[0].notes[1];

      expect(wrapper.vm.getTooltipText(note)).toEqual('Fatih Acet: comment 2 is rea…');
    });
  });
});

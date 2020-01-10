import { shallowMount } from '@vue/test-utils';
import DiffGutterAvatars from '~/diffs/components/diff_gutter_avatars.vue';
import discussionsMockData from '../mock_data/diff_discussions';

const getDiscussionsMockData = () => [Object.assign({}, discussionsMockData)];

describe('DiffGutterAvatars', () => {
  let wrapper;

  const findCollapseButton = () => wrapper.find('.diff-notes-collapse');
  const findMoreCount = () => wrapper.find('.diff-comments-more-count');
  const findUserAvatars = () => wrapper.findAll('.diff-comment-avatar');

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DiffGutterAvatars, {
      propsData: {
        ...props,
      },
      attachToDocument: true,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

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

    it('should emit toggleDiscussions event on button click', () => {
      findCollapseButton().trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().toggleLineDiscussions).toBeTruthy();
      });
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

    it('renders correct moreCount number', () => {
      expect(findMoreCount().text()).toBe('+2');
    });

    it('should emit toggleDiscussions event on avatars click', () => {
      findUserAvatars()
        .at(0)
        .trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().toggleLineDiscussions).toBeTruthy();
      });
    });

    it('should emit toggleDiscussions event on more count text click', () => {
      findMoreCount().trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().toggleLineDiscussions).toBeTruthy();
      });
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

      expect(wrapper.vm.getTooltipText(note)).toEqual('Fatih Acet: comment 2 is r...');
    });
  });
});

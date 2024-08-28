import { GlAvatarsInline } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ToggleRepliesWidget from '~/design_management/components/design_notes/toggle_replies_widget.vue';
import notes, { DISCUSSION_3 } from '../../mock_data/notes';

describe('Toggle replies widget component', () => {
  let wrapper;

  const findToggleWrapper = () => wrapper.findByTestId('toggle-comments-wrapper');
  const findToggleButton = () => wrapper.findByTestId('toggle-replies-button');
  const findRepliesButton = () => wrapper.findByTestId('replies-button');
  const findAvatarInline = () => wrapper.findComponent(GlAvatarsInline);

  const threeNotes = [...notes, DISCUSSION_3];

  function createComponent(props = {}) {
    wrapper = shallowMountExtended(ToggleRepliesWidget, {
      propsData: {
        collapsed: true,
        replies: notes,
        ...props,
      },
    });
  }

  describe('when replies are collapsed', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should not have expanded class', () => {
      expect(findToggleWrapper().classes()).not.toContain('expanded');
    });

    it('should render chevron-right icon on the toggle button', () => {
      expect(findToggleButton().props('icon')).toBe('chevron-right');
    });

    it('should have replies length on button', () => {
      expect(findRepliesButton().text()).toBe('2 replies');
    });

    it('renders the avatar inline component with default props', () => {
      expect(findAvatarInline().exists()).toBe(true);
      expect(findAvatarInline().props()).toMatchObject({
        maxVisible: 2,
        avatarSize: 24,
        collapsed: true,
        badgeSrOnlyText: '',
        badgeTooltipProp: 'name',
        badgeTooltipMaxChars: null,
      });
    });

    it('renders the avatar inline component with screen reader text', () => {
      createComponent({ replies: threeNotes });

      expect(findAvatarInline().exists()).toBe(true);
      expect(findAvatarInline().props('badgeSrOnlyText')).toBe('3 replies');
    });

    it('correctly passes author date to the avatar inline component', () => {
      expect(findAvatarInline().props('avatars')).toMatchObject([
        {
          avatarUrl:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          id: 'gid://gitlab/User/1',
          name: 'John',
          username: 'john.doe',
          webUrl: 'link-to-john-profile',
        },
        { name: 'Mary', webUrl: 'link-to-mary-profile' },
      ]);
    });
  });

  describe('when replies are expanded', () => {
    beforeEach(() => {
      createComponent({ collapsed: false });
    });

    it('should have aria-expanded set', () => {
      expect(findToggleWrapper().attributes('aria-expanded')).toBe('true');
    });

    it('should render chevron-down icon on the toggle button', () => {
      expect(findToggleButton().props('icon')).toBe('chevron-down');
    });

    it('should have Collapse replies text on button', () => {
      expect(findRepliesButton().text()).toBe('Collapse replies');
    });
  });

  it('should emit toggle event on toggle button click', async () => {
    createComponent();
    await findToggleButton().vm.$emit('click');

    expect(wrapper.emitted('toggle')).toHaveLength(1);
  });

  it('should emit toggle event on replies button click', () => {
    createComponent();
    findRepliesButton().vm.$emit('click');

    expect(wrapper.emitted('toggle')).toHaveLength(1);
  });
});

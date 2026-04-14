import { GlAvatarsInline, GlAnimatedChevronRightDownIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ToggleRepliesWidget from '~/notes/components/toggle_replies_widget.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { createNoteMock } from '../mock_data';

describe('toggle replies widget for notes', () => {
  const noteFromOtherUser = createNoteMock();
  noteFromOtherUser.author.username = 'fatihacet';

  const noteFromAnotherUser = createNoteMock();
  noteFromAnotherUser.author.username = 'mgreiling';
  noteFromAnotherUser.author.name = 'Mike Greiling';

  const replies = [
    createNoteMock(),
    createNoteMock(),
    createNoteMock(),
    noteFromOtherUser,
    noteFromAnotherUser,
  ];

  let wrapper;

  const mountComponent = (props) => {
    wrapper = mountExtended(ToggleRepliesWidget, {
      propsData: { replies, collapsed: false, ...props },
    });
  };

  // const findCollapseToggleButton = () =>
  //   wrapper.findComponentByRole('button', { text: ToggleRepliesWidget.i18n.collapseReplies });
  const findToggleButton = () => wrapper.findByTestId('replies-toggle');
  const findToggleIcon = () => wrapper.findComponent(GlAnimatedChevronRightDownIcon);
  const findRepliesButton = () => wrapper.findByRole('button', { text: '5 replies' });
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findAvatars = () => wrapper.findComponent(GlAvatarsInline);
  const findUserLink = () => wrapper.findByRole('link', { text: noteFromAnotherUser.author.name });

  it('supports custom tag', () => {
    mountComponent({ tag: 'span' });
    expect(wrapper.element.tagName).toBe('SPAN');
    expect(wrapper.element.getAttribute('aria-expanded')).toBeNull();
  });

  describe('collapsed state', () => {
    beforeEach(() => {
      mountComponent({ collapsed: true });
    });

    it('renders collapsed state elements', () => {
      expect(findToggleIcon().props('isOn')).toBe(false);
      expect(findToggleButton().attributes('aria-label')).toBe('Expand replies');
      expect(findAvatars().props('avatars')).toHaveLength(3);
      expect(findRepliesButton().exists()).toBe(true);
      expect(wrapper.text()).toContain('Last reply by');
      expect(findUserLink().exists()).toBe(true);
      expect(findTimeAgoTooltip().exists()).toBe(true);
    });

    it('emits "toggle" event when expand toggle button is clicked', () => {
      findToggleButton().trigger('click');

      expect(wrapper.emitted('toggle')).toEqual([[]]);
    });

    it('emits "toggle" event when replies button is clicked', () => {
      findRepliesButton().trigger('click');

      expect(wrapper.emitted('toggle')).toEqual([[]]);
    });
  });

  describe('expanded state', () => {
    beforeEach(() => {
      mountComponent({ collapsed: false });
    });

    it('renders expanded state elements', () => {
      expect(findToggleIcon().props('isOn')).toBe(true);
      expect(findToggleButton().attributes('aria-label')).toBe('Collapse replies');
    });

    it('emits "toggle" event when collapse toggle button is clicked', () => {
      findToggleButton().trigger('click');

      expect(wrapper.emitted('toggle')).toEqual([[]]);
    });
  });
});

import { GlAvatarsInline } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ToggleRepliesWidget from '~/notes/components/toggle_replies_widget.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { note } from '../mock_data';

describe('toggle replies widget for notes', () => {
  let wrapper;

  const deepCloneObject = (obj) => JSON.parse(JSON.stringify(obj));

  const noteFromOtherUser = deepCloneObject(note);
  noteFromOtherUser.author.username = 'fatihacet';

  const noteFromAnotherUser = deepCloneObject(note);
  noteFromAnotherUser.author.username = 'mgreiling';
  noteFromAnotherUser.author.name = 'Mike Greiling';

  const replies = [note, note, note, noteFromOtherUser, noteFromAnotherUser];

  const findCollapseToggleButton = () =>
    wrapper.findByRole('button', { text: ToggleRepliesWidget.i18n.collapseReplies });
  const findExpandToggleButton = () =>
    wrapper.findByRole('button', { text: ToggleRepliesWidget.i18n.expandReplies });
  const findRepliesButton = () => wrapper.findByRole('button', { text: '5 replies' });
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findAvatars = () => wrapper.findComponent(GlAvatarsInline);
  const findUserLink = () => wrapper.findByRole('link', { text: noteFromAnotherUser.author.name });

  const mountComponent = ({ collapsed = false }) =>
    mountExtended(ToggleRepliesWidget, { propsData: { replies, collapsed } });

  describe('collapsed state', () => {
    beforeEach(() => {
      wrapper = mountComponent({ collapsed: true });
    });

    it('renders collapsed state elements', () => {
      expect(findExpandToggleButton().exists()).toBe(true);
      expect(findAvatars().props('avatars')).toHaveLength(3);
      expect(findRepliesButton().exists()).toBe(true);
      expect(wrapper.text()).toContain('Last reply by');
      expect(findUserLink().exists()).toBe(true);
      expect(findTimeAgoTooltip().exists()).toBe(true);
    });

    it('emits "toggle" event when expand toggle button is clicked', () => {
      findExpandToggleButton().trigger('click');

      expect(wrapper.emitted('toggle')).toEqual([[]]);
    });

    it('emits "toggle" event when replies button is clicked', () => {
      findRepliesButton().trigger('click');

      expect(wrapper.emitted('toggle')).toEqual([[]]);
    });
  });

  describe('expanded state', () => {
    beforeEach(() => {
      wrapper = mountComponent({ collapsed: false });
    });

    it('renders expanded state elements', () => {
      expect(findCollapseToggleButton().exists()).toBe(true);
    });

    it('emits "toggle" event when collapse toggle button is clicked', () => {
      findCollapseToggleButton().trigger('click');

      expect(wrapper.emitted('toggle')).toEqual([[]]);
    });
  });
});

import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SidebarParticipants from '~/sidebar/components/participants/sidebar_participants.vue';

describe('SidebarParticipants component', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const participant = {
    id: 1,
    state: 'active',
    username: 'marcene',
    name: 'Allie Will',
    web_url: 'foo.com',
    avatar_url: 'gravatar.com/avatar/xxx',
  };

  const participants = [participant, { ...participant, id: 2 }, { ...participant, id: 3 }];

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findCollapsedIcon = () => wrapper.find('.sidebar-collapsed-icon');

  const mountComponent = (propsData) => shallowMount(SidebarParticipants, { propsData });

  describe('collapsed sidebar state', () => {
    it('shows loading spinner when loading', () => {
      wrapper = mountComponent({ loading: true });

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not show loading spinner when not loading', () => {
      wrapper = mountComponent({ loading: false });

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('shows participant count when given', () => {
      wrapper = mountComponent({ participants });

      expect(findCollapsedIcon().text()).toBe(participants.length.toString());
    });

    it('shows full participant count when there are hidden participants', () => {
      wrapper = mountComponent({ participants, numberOfLessParticipants: 1 });

      expect(findCollapsedIcon().text()).toBe(participants.length.toString());
    });

    it('clicking on participants icon emits `toggleSidebar` event', () => {
      wrapper = mountComponent({ participants, numberOfLessParticipants: 2 });

      findCollapsedIcon().trigger('click');

      expect(wrapper.emitted('toggleSidebar')).toEqual([[]]);
    });
  });

  describe('when not showing participants label', () => {
    beforeEach(() => {
      wrapper = mountComponent({ participants, showParticipantLabel: false });
    });

    it('does not show sidebar collapsed icon', () => {
      expect(findCollapsedIcon().exists()).toBe(false);
    });

    it('does not show participants label title', () => {
      expect(wrapper.find('.title').exists()).toBe(false);
    });
  });
});

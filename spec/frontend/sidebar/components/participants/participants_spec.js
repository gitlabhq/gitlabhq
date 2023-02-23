import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Participants from '~/sidebar/components/participants/participants.vue';

describe('Participants component', () => {
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
  const findMoreParticipantsButton = () => wrapper.findComponent(GlButton);
  const findCollapsedIcon = () => wrapper.find('.sidebar-collapsed-icon');
  const findParticipantsAuthor = () => wrapper.findAll('.participants-author');

  const mountComponent = (propsData) => shallowMount(Participants, { propsData });

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
  });

  describe('expanded sidebar state', () => {
    it('shows loading spinner when loading', () => {
      wrapper = mountComponent({ loading: true });

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('when only showing visible participants, shows an avatar only for each participant under the limit', () => {
      const numberOfLessParticipants = 2;
      wrapper = mountComponent({ participants, numberOfLessParticipants });

      expect(findParticipantsAuthor()).toHaveLength(numberOfLessParticipants);
    });

    it('when only showing all participants, each has an avatar', async () => {
      wrapper = mountComponent({ participants, numberOfLessParticipants: 2 });

      await findMoreParticipantsButton().vm.$emit('click');

      expect(findParticipantsAuthor()).toHaveLength(participants.length);
    });

    it('does not have more participants link when they can all be shown', () => {
      const numberOfLessParticipants = 100;
      wrapper = mountComponent({ participants, numberOfLessParticipants });

      expect(participants.length).toBeLessThan(numberOfLessParticipants);
      expect(findMoreParticipantsButton().exists()).toBe(false);
    });

    it('when too many participants, has more participants link to show more', () => {
      wrapper = mountComponent({ participants, numberOfLessParticipants: 2 });

      expect(findMoreParticipantsButton().text()).toBe('+ 1 more');
    });

    it('when too many participants and already showing them, has more participants link to show less', async () => {
      wrapper = mountComponent({ participants, numberOfLessParticipants: 2 });

      await findMoreParticipantsButton().vm.$emit('click');

      expect(findMoreParticipantsButton().text()).toBe('- show less');
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

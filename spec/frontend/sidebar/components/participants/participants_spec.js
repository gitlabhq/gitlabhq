import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Participants from '~/sidebar/components/participants/participants.vue';

const PARTICIPANT = {
  id: 1,
  state: 'active',
  username: 'marcene',
  name: 'Allie Will',
  web_url: 'foo.com',
  avatar_url: 'gravatar.com/avatar/xxx',
};

const PARTICIPANT_LIST = [PARTICIPANT, { ...PARTICIPANT, id: 2 }, { ...PARTICIPANT, id: 3 }];

describe('Participants', () => {
  let wrapper;

  const getMoreParticipantsButton = () => wrapper.find('[data-testid="more-participants"]');
  const getCollapsedParticipantsCount = () => wrapper.find('[data-testid="collapsed-count"]');

  const mountComponent = (propsData) =>
    shallowMount(Participants, {
      propsData,
    });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('collapsed sidebar state', () => {
    it('shows loading spinner when loading', () => {
      wrapper = mountComponent({
        loading: true,
      });

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('does not show loading spinner not loading', () => {
      wrapper = mountComponent({
        loading: false,
      });

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
    });

    it('shows participant count when given', () => {
      wrapper = mountComponent({
        loading: false,
        participants: PARTICIPANT_LIST,
      });

      expect(getCollapsedParticipantsCount().text()).toBe(`${PARTICIPANT_LIST.length}`);
    });

    it('shows full participant count when there are hidden participants', () => {
      wrapper = mountComponent({
        loading: false,
        participants: PARTICIPANT_LIST,
        numberOfLessParticipants: 1,
      });

      expect(getCollapsedParticipantsCount().text()).toBe(`${PARTICIPANT_LIST.length}`);
    });
  });

  describe('expanded sidebar state', () => {
    it('shows loading spinner when loading', () => {
      wrapper = mountComponent({
        loading: true,
      });

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('when only showing visible participants, shows an avatar only for each participant under the limit', async () => {
      const numberOfLessParticipants = 2;
      wrapper = mountComponent({
        loading: false,
        participants: PARTICIPANT_LIST,
        numberOfLessParticipants,
      });

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        isShowingMoreParticipants: false,
      });

      await nextTick();
      expect(wrapper.findAll('.participants-author')).toHaveLength(numberOfLessParticipants);
    });

    it('when only showing all participants, each has an avatar', async () => {
      wrapper = mountComponent({
        loading: false,
        participants: PARTICIPANT_LIST,
        numberOfLessParticipants: 2,
      });

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        isShowingMoreParticipants: true,
      });

      await nextTick();
      expect(wrapper.findAll('.participants-author')).toHaveLength(PARTICIPANT_LIST.length);
    });

    it('does not have more participants link when they can all be shown', () => {
      const numberOfLessParticipants = 100;
      wrapper = mountComponent({
        loading: false,
        participants: PARTICIPANT_LIST,
        numberOfLessParticipants,
      });

      expect(PARTICIPANT_LIST.length).toBeLessThan(numberOfLessParticipants);
      expect(getMoreParticipantsButton().exists()).toBe(false);
    });

    it('when too many participants, has more participants link to show more', async () => {
      wrapper = mountComponent({
        loading: false,
        participants: PARTICIPANT_LIST,
        numberOfLessParticipants: 2,
      });

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        isShowingMoreParticipants: false,
      });

      await nextTick();
      expect(getMoreParticipantsButton().text()).toBe('+ 1 more');
    });

    it('when too many participants and already showing them, has more participants link to show less', async () => {
      wrapper = mountComponent({
        loading: false,
        participants: PARTICIPANT_LIST,
        numberOfLessParticipants: 2,
      });

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        isShowingMoreParticipants: true,
      });

      await nextTick();
      expect(getMoreParticipantsButton().text()).toBe('- show less');
    });

    it('clicking more participants link emits event', () => {
      wrapper = mountComponent({
        loading: false,
        participants: PARTICIPANT_LIST,
        numberOfLessParticipants: 2,
      });

      expect(wrapper.vm.isShowingMoreParticipants).toBe(false);

      getMoreParticipantsButton().vm.$emit('click');

      expect(wrapper.vm.isShowingMoreParticipants).toBe(true);
    });

    it('clicking on participants icon emits `toggleSidebar` event', async () => {
      wrapper = mountComponent({
        loading: false,
        participants: PARTICIPANT_LIST,
        numberOfLessParticipants: 2,
      });

      const spy = jest.spyOn(wrapper.vm, '$emit');

      wrapper.find('.sidebar-collapsed-icon').trigger('click');

      await nextTick();
      expect(spy).toHaveBeenCalledWith('toggleSidebar');
      spy.mockRestore();
    });
  });

  describe('when not showing participants label', () => {
    beforeEach(() => {
      wrapper = mountComponent({
        participants: PARTICIPANT_LIST,
        showParticipantLabel: false,
      });
    });

    it('does not show sidebar collapsed icon', () => {
      expect(wrapper.find('.sidebar-collapsed-icon').exists()).toBe(false);
    });

    it('does not show participants label title', () => {
      expect(wrapper.find('.title').exists()).toBe(false);
    });
  });
});

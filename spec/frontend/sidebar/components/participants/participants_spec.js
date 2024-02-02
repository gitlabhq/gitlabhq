import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Participants from '~/sidebar/components/participants/participants.vue';

describe('Participants component', () => {
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

  const findMoreParticipantsButton = () => wrapper.findComponent(GlButton);
  const findParticipantsAuthor = () => wrapper.findAll('.author-link');

  const mountComponent = (propsData) => shallowMount(Participants, { propsData });

  describe('expanded sidebar state', () => {
    it('when only showing visible participants, shows an avatar only for each participant under the limit', () => {
      const numberOfLessParticipants = 2;
      wrapper = mountComponent({ participants, numberOfLessParticipants });

      expect(findParticipantsAuthor()).toHaveLength(numberOfLessParticipants);
    });

    it('participants link has data attributes and class present for popover support', () => {
      const numberOfLessParticipants = 2;
      wrapper = mountComponent({ participants, numberOfLessParticipants });

      const participantsLink = wrapper.find('.js-user-link');

      expect(participantsLink.attributes()).toMatchObject({
        href: `${participant.web_url}`,
        'data-user-id': `${participant.id}`,
        'data-username': `${participant.username}`,
      });
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
  });
});

import { mount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';

import EmailParticipantsWarning from '~/notes/components/email_participants_warning.vue';

describe('Email Participants Warning Component', () => {
  let wrapper;

  const findMoreButton = () => wrapper.findComponent(GlButton);

  const createWrapper = (emails) => {
    wrapper = mount(EmailParticipantsWarning, {
      propsData: { emails },
    });
  };

  describe('with 3 or less emails', () => {
    beforeEach(() => {
      createWrapper(['a@gitlab.com', 'b@gitlab.com', 'c@gitlab.com']);
    });

    it('more button does not exist', () => {
      expect(findMoreButton().exists()).toBe(false);
    });

    it('all emails are displayed', () => {
      expect(wrapper.text()).toBe(
        'a@gitlab.com, b@gitlab.com, and c@gitlab.com will be notified of your comment.',
      );
    });
  });

  describe('with more than 3 emails', () => {
    beforeEach(() => {
      createWrapper(['a@gitlab.com', 'b@gitlab.com', 'c@gitlab.com', 'd@gitlab.com']);
    });

    it('only displays first 3 emails', () => {
      expect(wrapper.text()).toContain('a@gitlab.com, b@gitlab.com, c@gitlab.com');
      expect(wrapper.text()).not.toContain('d@gitlab.com');
    });

    it('more button does exist', () => {
      expect(findMoreButton().exists()).toBe(true);
    });

    it('more button displays the correct wordage', () => {
      expect(findMoreButton().text()).toBe('and 1 more');
    });

    describe('when more button clicked', () => {
      beforeEach(() => {
        findMoreButton().vm.$emit('click');
      });

      it('more button no longer exists', () => {
        expect(findMoreButton().exists()).toBe(false);
      });

      it('all emails are displayed', () => {
        expect(wrapper.text()).toBe(
          'a@gitlab.com, b@gitlab.com, c@gitlab.com, and d@gitlab.com will be notified of your comment.',
        );
      });
    });
  });
});

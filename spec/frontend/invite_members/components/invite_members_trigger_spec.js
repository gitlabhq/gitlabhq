import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import eventHub from '~/invite_members/event_hub';

jest.mock('~/experimentation/experiment_tracking');

const displayText = 'Invite team members';
let wrapper;

const createComponent = (props = {}) => {
  wrapper = shallowMount(InviteMembersTrigger, {
    propsData: {
      displayText,
      ...props,
    },
  });
};

describe('InviteMembersTrigger', () => {
  const findButton = () => wrapper.findComponent(GlButton);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('displayText', () => {
    it('includes the correct displayText for the button', () => {
      createComponent();

      expect(findButton().text()).toBe(displayText);
    });
  });

  describe('clicking the link', () => {
    let spy;

    beforeEach(() => {
      spy = jest.spyOn(eventHub, '$emit');
    });

    it('emits openModal from an unknown source', () => {
      createComponent();

      findButton().vm.$emit('click');

      expect(spy).toHaveBeenCalledWith('openModal', { inviteeType: 'members', source: 'unknown' });
    });

    it('emits openModal from a named source', () => {
      createComponent({ triggerSource: '_trigger_source_' });

      findButton().vm.$emit('click');

      expect(spy).toHaveBeenCalledWith('openModal', {
        inviteeType: 'members',
        source: '_trigger_source_',
      });
    });
  });

  describe('tracking', () => {
    it('tracks on mounting', () => {
      createComponent({ trackExperiment: '_track_experiment_' });

      expect(ExperimentTracking).toHaveBeenCalledWith('_track_experiment_');
      expect(ExperimentTracking.prototype.event).toHaveBeenCalledWith('comment_invite_shown');
    });

    it('does not track on mounting', () => {
      createComponent();

      expect(ExperimentTracking).not.toHaveBeenCalledWith('_track_experiment_');
    });
  });
});

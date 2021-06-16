import { GlButton, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import eventHub from '~/invite_members/event_hub';

jest.mock('~/experimentation/experiment_tracking');

const displayText = 'Invite team members';
const triggerSource = '_trigger_source_';

let wrapper;
let triggerProps;
let findButton;
const triggerComponent = {
  button: GlButton,
  anchor: GlLink,
};

const createComponent = (props = {}) => {
  wrapper = shallowMount(InviteMembersTrigger, {
    propsData: {
      displayText,
      ...triggerProps,
      ...props,
    },
  });
};

describe.each(['button', 'anchor'])('with triggerElement as %s', (triggerElement) => {
  triggerProps = { triggerElement, triggerSource };
  findButton = () => wrapper.findComponent(triggerComponent[triggerElement]);

  afterEach(() => {
    wrapper.destroy();
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

    it('emits openModal from a named source', () => {
      createComponent();

      findButton().vm.$emit('click');

      expect(spy).toHaveBeenCalledWith('openModal', {
        inviteeType: 'members',
        source: triggerSource,
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

    it('does not add tracking attributes', () => {
      createComponent();

      expect(findButton().attributes('data-track-event')).toBeUndefined();
      expect(findButton().attributes('data-track-label')).toBeUndefined();
    });

    it('adds tracking attributes', () => {
      createComponent({ label: '_label_', event: '_event_' });

      expect(findButton().attributes('data-track-event')).toBe('_event_');
      expect(findButton().attributes('data-track-label')).toBe('_label_');
    });
  });
});

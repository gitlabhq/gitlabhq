import { GlButton, GlLink, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import eventHub from '~/invite_members/event_hub';
import { TRIGGER_ELEMENT_BUTTON, TRIGGER_ELEMENT_SIDE_NAV } from '~/invite_members/constants';

jest.mock('~/experimentation/experiment_tracking');

const displayText = 'Invite team members';
const triggerSource = '_trigger_source_';

let wrapper;
let triggerProps;
let findButton;
const triggerComponent = {
  button: GlButton,
  anchor: GlLink,
  'side-nav': GlLink,
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

const triggerItems = [
  {
    triggerElement: TRIGGER_ELEMENT_BUTTON,
  },
  {
    triggerElement: 'anchor',
  },
  {
    triggerElement: TRIGGER_ELEMENT_SIDE_NAV,
    icon: 'plus',
  },
];

describe.each(triggerItems)('with triggerElement as %s', (triggerItem) => {
  triggerProps = { ...triggerItem, triggerSource };

  findButton = () => wrapper.findComponent(triggerComponent[triggerItem.triggerElement]);

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
        source: triggerSource,
      });
    });
  });

  describe('tracking', () => {
    it('does not add tracking attributes', () => {
      createComponent();

      expect(findButton().attributes('data-track-action')).toBeUndefined();
      expect(findButton().attributes('data-track-label')).toBeUndefined();
    });

    it('adds tracking attributes', () => {
      createComponent({ label: '_label_', event: '_event_' });

      expect(findButton().attributes('data-track-action')).toBe('_event_');
      expect(findButton().attributes('data-track-label')).toBe('_label_');
    });
  });
});

describe('side-nav with icon', () => {
  it('includes the specified icon with correct size when triggerElement is link', () => {
    const findIcon = () => wrapper.findComponent(GlIcon);

    createComponent({ triggerElement: TRIGGER_ELEMENT_SIDE_NAV, icon: 'plus' });

    expect(findIcon().exists()).toBe(true);
    expect(findIcon().props('name')).toBe('plus');
  });
});

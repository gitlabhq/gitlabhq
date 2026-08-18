import { GlButton, GlLink, GlDropdownItem, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import eventHub from '~/invite_members/event_hub';
import {
  TRIGGER_ELEMENT_BUTTON,
  TRIGGER_ELEMENT_WITH_EMOJI,
  TRIGGER_ELEMENT_DROPDOWN_WITH_EMOJI,
  TRIGGER_ELEMENT_DISCLOSURE_DROPDOWN,
} from '~/invite_members/constants';
import { GlEmoji } from '../mock_data/member_modal';

let mockFailModuleLoad = false;
const mockInitInviteMembersModal = jest.fn();

jest.mock('~/experimentation/experiment_tracking');
jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/invite_members/init_invite_members_modal', () => ({
  __esModule: true,
  get default() {
    if (mockFailModuleLoad) {
      throw new Error('chunk load failed');
    }
    return mockInitInviteMembersModal;
  },
}));

beforeEach(() => {
  mockFailModuleLoad = false;
});

const displayText = 'Invite team members';
const triggerSource = '_trigger_source_';

let wrapper;
let triggerProps;
let findButton;
const triggerComponent = {
  button: GlButton,
  anchor: GlLink,
  'text-emoji': GlLink,
  'dropdown-text-emoji': GlDropdownItem,
  'dropdown-text': GlButton,
};

const createComponent = (props = {}) => {
  wrapper = shallowMount(InviteMembersTrigger, {
    propsData: {
      displayText,
      ...triggerProps,
      ...props,
    },
    stubs: {
      GlEmoji,
      GlDisclosureDropdownItem,
      GlButton,
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
    triggerElement: TRIGGER_ELEMENT_WITH_EMOJI,
    icon: 'shaking_hands',
  },
];

describe.each(triggerItems)('with triggerElement as %s', (triggerItem) => {
  triggerProps = { ...triggerItem, triggerSource };

  findButton = () => wrapper.findComponent(triggerComponent[triggerItem.triggerElement]);

  describe('configurable attributes', () => {
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

    it('emits openModal from a named source', async () => {
      createComponent();

      findButton().vm.$emit('click');
      await waitForPromises();

      expect(spy).toHaveBeenCalledWith('open-modal', {
        source: triggerSource,
      });
    });

    it('initializes the modal before emitting, so the event is not missed', async () => {
      const callOrder = [];
      mockInitInviteMembersModal.mockImplementation(() => callOrder.push('init'));
      spy.mockImplementation(() => callOrder.push('emit'));

      createComponent();

      findButton().vm.$emit('click');
      await waitForPromises();

      expect(callOrder).toEqual(['init', 'emit']);
    });

    it('still emits and reports to Sentry when the modal fails to initialize', async () => {
      const error = new Error('failed to initialize');
      mockInitInviteMembersModal.mockImplementationOnce(() => {
        throw error;
      });

      createComponent();

      findButton().vm.$emit('click');
      await waitForPromises();

      expect(captureException).toHaveBeenCalledWith(error);
      expect(spy).toHaveBeenCalledWith('open-modal', {
        source: triggerSource,
      });
    });

    it('still emits and reports to Sentry when the modal chunk fails to load', async () => {
      mockFailModuleLoad = true;

      createComponent();

      findButton().vm.$emit('click');
      await waitForPromises();

      expect(captureException).toHaveBeenCalledWith(expect.any(Error));
      expect(spy).toHaveBeenCalledWith('open-modal', {
        source: triggerSource,
      });
    });
  });
});

describe('link with emoji', () => {
  it('includes the specified icon with correct size when triggerElement is link', () => {
    const findEmoji = () => wrapper.findComponent(GlEmoji);

    createComponent({ triggerElement: TRIGGER_ELEMENT_WITH_EMOJI, icon: 'shaking_hands' });

    expect(findEmoji().exists()).toBe(true);
    expect(findEmoji().attributes('data-name')).toBe('shaking_hands');
  });
});

describe('dropdown item with emoji', () => {
  it('includes the specified icon with correct size when triggerElement is link', () => {
    const findEmoji = () => wrapper.findComponent(GlEmoji);

    createComponent({ triggerElement: TRIGGER_ELEMENT_DROPDOWN_WITH_EMOJI, icon: 'shaking_hands' });

    expect(findEmoji().exists()).toBe(true);
    expect(findEmoji().attributes('data-name')).toBe('shaking_hands');
  });
});

describe('disclosure dropdown item', () => {
  const findTrigger = () => wrapper.findComponent(GlDisclosureDropdownItem);

  beforeEach(() => {
    createComponent({ triggerElement: TRIGGER_ELEMENT_DISCLOSURE_DROPDOWN });
  });

  it('renders a trigger button', () => {
    expect(findTrigger().exists()).toBe(true);
    expect(findTrigger().text()).toBe(displayText);
  });

  it('emits modalOpened which clicked', async () => {
    findTrigger().vm.$emit('action');
    await waitForPromises();

    expect(wrapper.emitted('modal-opened')).toHaveLength(1);
  });
});

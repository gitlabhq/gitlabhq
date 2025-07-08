import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BypassConfirmationMessage from '~/members/placeholders/components/bypass_confirmation_message.vue';

describe('BypassConfirmationMessage', () => {
  let wrapper;

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(BypassConfirmationMessage, {
      provide: {
        ...provide,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  describe('when allowBypassPlaceholderConfirmation is null', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders nothing', () => {
      expect(wrapper.text()).toBe('');
    });
  });

  describe('when allowBypassPlaceholderConfirmation is "admin"', () => {
    beforeEach(() => {
      createComponent({ provide: { allowBypassPlaceholderConfirmation: 'admin' } });
    });

    it('renders the admin bypass confirmation message', () => {
      expect(wrapper.text()).toBe(
        'The Skip confirmation when administrators reassign placeholder users setting is enabled. Users do not have to approve the reassignment, and contributions are reassigned immediately.',
      );
    });
  });

  describe('when allowBypassPlaceholderConfirmation is "group_owner"', () => {
    beforeEach(() => {
      createComponent({ provide: { allowBypassPlaceholderConfirmation: 'group_owner' } });
    });

    it('renders the group owner bypass confirmation message', () => {
      expect(wrapper.text()).toBe(
        'The Skip confirmation when group owners reassign placeholder users to enterprise users setting is enabled. Enterprise users do not have to approve the reassignment, and contributions are reassigned immediately.',
      );
    });
  });

  describe('when allowBypassPlaceholderConfirmation is unknown', () => {
    beforeEach(() => {
      createComponent({ provide: { allowBypassPlaceholderConfirmation: 'unknown' } });
    });

    it('renders nothing', () => {
      expect(wrapper.text()).toBe('');
    });
  });
});

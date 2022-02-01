import { GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Component from '~/groups/components/transfer_group_form.vue';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';
import NamespaceSelect from '~/vue_shared/components/namespace_select/namespace_select.vue';

describe('Transfer group form', () => {
  let wrapper;

  const confirmButtonText = 'confirm';
  const confirmationPhrase = 'confirmation-phrase';
  const paidGroupHelpLink = 'some/fake/link';
  const groups = [
    {
      id: 1,
      humanName: 'Group 1',
    },
    {
      id: 2,
      humanName: 'Group 2',
    },
  ];

  const defaultProps = {
    parentGroups: { groups },
    paidGroupHelpLink,
    isPaidGroup: false,
    confirmationPhrase,
    confirmButtonText,
  };

  const createComponent = (propsData = {}) =>
    shallowMountExtended(Component, {
      propsData: {
        ...defaultProps,
        ...propsData,
      },
      stubs: { GlSprintf },
    });

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findConfirmDanger = () => wrapper.findComponent(ConfirmDanger);
  const findNamespaceSelect = () => wrapper.findComponent(NamespaceSelect);
  const findHiddenInput = () => wrapper.find('[name="new_parent_group_id"]');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the namespace select component', () => {
      expect(findNamespaceSelect().exists()).toBe(true);
    });

    it('sets the namespace select properties', () => {
      expect(findNamespaceSelect().props()).toMatchObject({
        defaultText: 'Select parent group',
        fullWidth: false,
        includeHeaders: false,
        emptyNamespaceTitle: 'No parent group',
        includeEmptyNamespace: true,
        data: { groups },
      });
    });

    it('renders the hidden input field', () => {
      expect(findHiddenInput().exists()).toBe(true);
      expect(findHiddenInput().attributes('value')).toBeUndefined();
    });

    it('does not render the alert message', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('renders the confirm danger component', () => {
      expect(findConfirmDanger().exists()).toBe(true);
    });

    it('sets the confirm danger properties', () => {
      expect(findConfirmDanger().props()).toMatchObject({
        buttonClass: 'qa-transfer-button',
        disabled: true,
        buttonText: confirmButtonText,
        phrase: confirmationPhrase,
      });
    });
  });

  describe('with a selected project', () => {
    const [firstGroup] = groups;
    beforeEach(() => {
      wrapper = createComponent();
      findNamespaceSelect().vm.$emit('select', firstGroup);
    });

    it('sets the confirm danger disabled property to false', () => {
      expect(findConfirmDanger().props()).toMatchObject({ disabled: false });
    });

    it('sets the hidden input field', () => {
      expect(findHiddenInput().exists()).toBe(true);
      expect(parseInt(findHiddenInput().attributes('value'), 10)).toBe(firstGroup.id);
    });

    it('emits "confirm" event when the danger modal is confirmed', () => {
      expect(wrapper.emitted('confirm')).toBeUndefined();

      findConfirmDanger().vm.$emit('confirm');

      expect(wrapper.emitted('confirm')).toHaveLength(1);
    });
  });

  describe('isPaidGroup = true', () => {
    beforeEach(() => {
      wrapper = createComponent({ isPaidGroup: true });
    });

    it('disables the transfer button', () => {
      expect(findConfirmDanger().props()).toMatchObject({ disabled: true });
    });

    it('hides the namespace selector button', () => {
      expect(findNamespaceSelect().exists()).toBe(false);
    });
  });
});

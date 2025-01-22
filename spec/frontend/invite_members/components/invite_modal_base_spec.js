import { GlDatepicker, GlFormGroup, GlSprintf, GlModal, GlIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { RENDER_ALL_SLOTS_TEMPLATE, stubComponent } from 'helpers/stub_component';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InviteModalBase from '~/invite_members/components/invite_modal_base.vue';
import ContentTransition from '~/invite_members/components/content_transition.vue';
import RoleSelector from '~/members/components/role_selector.vue';
import { roleDropdownItems } from '~/members/utils';

import {
  CANCEL_BUTTON_TEXT,
  INVITE_BUTTON_TEXT_DISABLED,
  INVITE_BUTTON_TEXT,
  ON_SHOW_TRACK_LABEL,
} from '~/invite_members/constants';

import { propsData, membersPath, purchasePath } from '../mock_data/modal_base';

describe('InviteModalBase', () => {
  let wrapper;
  const dropdownItems = roleDropdownItems({ validRoles: propsData.accessLevels });

  const createComponent = ({ props = {}, stubs = {}, mountFn = shallowMountExtended } = {}) => {
    const requiredStubs =
      mountFn === mountExtended
        ? {}
        : {
            ContentTransition,
            GlCollapsibleListbox: true,
            GlSprintf,
            GlFormGroup: stubComponent(GlFormGroup, {
              props: ['state', 'invalidFeedback'],
            }),
          };

    wrapper = mountFn(InviteModalBase, {
      propsData: {
        ...propsData,
        accessLevels: { validRoles: propsData.accessLevels },
        ...props,
      },
      stubs: {
        GlModal: stubComponent(GlModal, { template: RENDER_ALL_SLOTS_TEMPLATE }),
        ...requiredStubs,
        ...stubs,
      },
    });
  };

  const findRoleSelector = () => wrapper.findComponent(RoleSelector);
  const findDatepicker = () => wrapper.findComponent(GlDatepicker);
  const findLink = () => wrapper.findByTestId('invite-modal-help-link');
  const findAccessExpirationHelpLink = () =>
    wrapper.findByTestId('invite-modal-access-expiration-link');
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findIntroText = () => wrapper.findByTestId('modal-base-intro-text').text();
  const findMembersFormGroup = () => wrapper.findByTestId('members-form-group');
  const findDisabledInput = () => wrapper.findByTestId('disabled-input');
  const findCancelButton = () => wrapper.findByTestId('invite-modal-cancel');
  const findActionButton = () => wrapper.findByTestId('invite-modal-submit');
  const findModal = () => wrapper.findComponent(GlModal);

  describe('rendering the modal', () => {
    let trackingSpy;

    const expectTracking = (action, label = undefined, category = undefined) =>
      expect(trackingSpy).toHaveBeenCalledWith(category, action, { label, category });

    beforeEach(() => {
      createComponent();
    });

    it('renders the modal with the correct title', () => {
      expect(findModal().props('title')).toBe(propsData.modalTitle);
    });

    it('displays the introText', () => {
      expect(findIntroText()).toBe(propsData.labelIntroText);
    });

    it('renders the Cancel button text correctly', () => {
      expect(findCancelButton().text()).toBe(CANCEL_BUTTON_TEXT);
    });

    it('renders the Invite button correctly', () => {
      const actionButton = findActionButton();

      expect(actionButton.text()).toBe(INVITE_BUTTON_TEXT);

      expect(actionButton.props()).toMatchObject({
        variant: 'confirm',
        disabled: false,
        loading: false,
      });
    });

    describe('rendering the role selector', () => {
      beforeEach(() => {
        createComponent({
          props: { isLoadingRoles: true },
          mountFn: mountExtended,
        });
      });

      it('passes roles to the dropdown', () => {
        const expectedRoles = roleDropdownItems({ validRoles: propsData.accessLevels });

        expect(findRoleSelector().props('roles')).toEqual(expectedRoles);
      });

      it('passes `isLoadingRoles` prop to the dropdown', () => {
        expect(findRoleSelector().props('loading')).toBe(true);
      });

      it('sets the default dropdown text to the default access level name', () => {
        expect(findRoleSelector().props('value').text).toBe('Reporter');
      });

      it('resets the dropdown to the default option when modal is canceled', async () => {
        findRoleSelector().vm.$emit('input', dropdownItems.flatten[2]);
        await nextTick();
        // Sanity check to verify that the selected role is not the default.
        expect(findRoleSelector().props('value').text).toBe('Developer');

        await findCancelButton().trigger('click');

        expect(findRoleSelector().props('value').text).toEqual('Reporter');
      });
    });

    describe('rendering the help link', () => {
      beforeEach(() => {
        createComponent({
          mountFn: mountExtended,
        });
      });

      it('renders the correct link', () => {
        expect(findLink().attributes('href')).toBe(propsData.helpLink);
      });
    });

    describe('rendering the access expiration help link', () => {
      beforeEach(() => {
        createComponent({
          mountFn: mountExtended,
        });
      });

      it('renders the correct link', () => {
        expect(findAccessExpirationHelpLink().attributes('href')).toBe(
          propsData.accessExpirationHelpLink,
        );
      });
    });

    describe('rendering the access expiration date field', () => {
      it('renders the datepicker', () => {
        expect(findDatepicker().exists()).toBe(true);
      });
    });

    it('renders the members form group', () => {
      expect(findMembersFormGroup().props()).toEqual({
        invalidFeedback: '',
        state: null,
      });
    });

    it('renders description', () => {
      createComponent({ stubs: { GlFormGroup } });

      expect(findMembersFormGroup().attributes('description')).toContain(
        propsData.formGroupDescription,
      );
    });

    describe('when users limit is reached', () => {
      beforeEach(() => {
        createComponent(
          { props: { usersLimitDataset: { membersPath, purchasePath, reachedLimit: true } } },
          { stubs: { GlModal, GlFormGroup } },
        );
      });

      it('tracks actions', () => {
        createComponent({
          props: { usersLimitDataset: { reachedLimit: true } },
          stubs: { GlFormGroup, GlModal },
        });
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

        findModal().vm.$emit('shown');
        expectTracking('render', ON_SHOW_TRACK_LABEL, 'default');

        unmockTracking();
      });
    });

    describe('when user limit is close on a personal namespace', () => {
      beforeEach(() => {
        createComponent({
          props: {
            usersLimitDataset: {
              membersPath,
              userNamespace: true,
              closeToDashboardLimit: true,
              reachedLimit: false,
            },
          },
          stubs: { GlModal, GlFormGroup },
        });
      });

      it('renders correct buttons', () => {
        const cancelButton = findCancelButton();
        const actionButton = findActionButton();

        expect(cancelButton.text()).toBe(INVITE_BUTTON_TEXT_DISABLED);
        expect(cancelButton.attributes('href')).toBe(membersPath);

        expect(actionButton.text()).toBe(INVITE_BUTTON_TEXT);
        expect(actionButton.attributes('href')).toBe(); // default submit button
      });
    });

    describe('when users limit is not reached', () => {
      const textRegex =
        /Select maximum role\s*Invited members are limited to this role or their current group role, whichever is higher. Learn more about roles.\s*Access expiration date \(optional\)/;

      beforeEach(() => {
        createComponent({ props: { reachedLimit: false }, stubs: { GlModal, GlFormGroup } });
      });

      it('renders correct blocks', () => {
        expect(findIcon().exists()).toBe(false);
        expect(findDisabledInput().exists()).toBe(false);
        expect(findRoleSelector().exists()).toBe(true);
        expect(findDatepicker().exists()).toBe(true);
        expect(wrapper.findComponent(GlModal).text()).toMatch(textRegex);
      });

      it('renders correct buttons', () => {
        expect(findCancelButton().text()).toBe(CANCEL_BUTTON_TEXT);
        expect(findActionButton().text()).toBe(INVITE_BUTTON_TEXT);
      });
    });
  });

  it('with isLoading, shows loading for invite button', () => {
    createComponent({
      props: {
        isLoading: true,
      },
    });

    expect(findActionButton().props('loading')).toBe(true);
  });

  it('with invalidFeedbackMessage, set members form group exception state', () => {
    createComponent({
      props: {
        invalidFeedbackMessage: 'invalid message!',
      },
    });

    expect(findMembersFormGroup().props()).toEqual({
      invalidFeedback: 'invalid message!',
      state: false,
    });
  });

  it('emits the shown event when the modal is shown', () => {
    createComponent();
    // Verify that the shown event isn't emitted when the component is first created.
    expect(wrapper.emitted('shown')).toBeUndefined();

    findModal().vm.$emit('shown');

    expect(wrapper.emitted('shown')).toHaveLength(1);
  });
});

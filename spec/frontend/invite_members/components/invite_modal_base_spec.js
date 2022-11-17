import {
  GlDropdown,
  GlDropdownItem,
  GlDatepicker,
  GlFormGroup,
  GlSprintf,
  GlLink,
  GlModal,
  GlIcon,
} from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InviteModalBase from '~/invite_members/components/invite_modal_base.vue';
import ContentTransition from '~/vue_shared/components/content_transition.vue';

import {
  CANCEL_BUTTON_TEXT,
  INVITE_BUTTON_TEXT_DISABLED,
  INVITE_BUTTON_TEXT,
  ON_SHOW_TRACK_LABEL,
} from '~/invite_members/constants';

import { propsData, membersPath, purchasePath } from '../mock_data/modal_base';

describe('InviteModalBase', () => {
  let wrapper;

  const createComponent = (props = {}, stubs = {}) => {
    wrapper = shallowMountExtended(InviteModalBase, {
      propsData: {
        ...propsData,
        ...props,
      },
      stubs: {
        ContentTransition,
        GlModal: stubComponent(GlModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
        }),
        GlDropdown: true,
        GlDropdownItem: true,
        GlSprintf,
        GlFormGroup: stubComponent(GlFormGroup, {
          props: ['state', 'invalidFeedback'],
        }),
        ...stubs,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => findDropdown().findAllComponents(GlDropdownItem);
  const findDatepicker = () => wrapper.findComponent(GlDatepicker);
  const findLink = () => wrapper.findComponent(GlLink);
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findIntroText = () => wrapper.findByTestId('modal-base-intro-text').text();
  const findMembersFormGroup = () => wrapper.findByTestId('members-form-group');
  const findDisabledInput = () => wrapper.findByTestId('disabled-input');
  const findCancelButton = () => wrapper.find('.js-modal-action-cancel');
  const findActionButton = () => wrapper.find('.js-modal-action-primary');

  describe('rendering the modal', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the modal with the correct title', () => {
      expect(wrapper.findComponent(GlModal).props('title')).toBe(propsData.modalTitle);
    });

    it('displays the introText', () => {
      expect(findIntroText()).toBe(propsData.labelIntroText);
    });

    it('renders the Cancel button text correctly', () => {
      expect(wrapper.findComponent(GlModal).props('actionCancel')).toMatchObject({
        text: CANCEL_BUTTON_TEXT,
      });
    });

    it('renders the Invite button correctly', () => {
      expect(wrapper.findComponent(GlModal).props('actionPrimary')).toMatchObject({
        text: INVITE_BUTTON_TEXT,
        attributes: {
          variant: 'confirm',
          disabled: false,
          loading: false,
          'data-qa-selector': 'invite_button',
        },
      });
    });

    describe('rendering the access levels dropdown', () => {
      it('sets the default dropdown text to the default access level name', () => {
        expect(findDropdown().attributes('text')).toBe('Guest');
      });

      it('renders dropdown items for each accessLevel', () => {
        expect(findDropdownItems()).toHaveLength(5);
      });
    });

    describe('rendering the help link', () => {
      it('renders the correct link', () => {
        expect(findLink().attributes('href')).toBe(propsData.helpLink);
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
      createComponent({}, { GlFormGroup });

      expect(findMembersFormGroup().attributes('description')).toContain(
        propsData.formGroupDescription,
      );
    });

    describe('when users limit is reached', () => {
      let trackingSpy;

      const expectTracking = (action, label) =>
        expect(trackingSpy).toHaveBeenCalledWith('default', action, {
          label,
          category: 'default',
        });

      beforeEach(() => {
        createComponent(
          { usersLimitDataset: { membersPath, purchasePath, reachedLimit: true } },
          { GlModal, GlFormGroup },
        );
      });

      it('tracks actions', () => {
        createComponent({ usersLimitDataset: { reachedLimit: true } }, { GlFormGroup, GlModal });
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

        const modal = wrapper.findComponent(GlModal);

        modal.vm.$emit('shown');
        expectTracking('render', ON_SHOW_TRACK_LABEL);

        unmockTracking();
      });
    });

    describe('when user limit is close on a personal namespace', () => {
      beforeEach(() => {
        createComponent(
          {
            usersLimitDataset: {
              membersPath,
              userNamespace: true,
              closeToDashboardLimit: true,
              reachedLimit: false,
            },
          },
          { GlModal, GlFormGroup },
        );
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
      const textRegex = /Select a role.+Read more about role permissions Access expiration date \(optional\)/;

      beforeEach(() => {
        createComponent({ reachedLimit: false }, { GlModal, GlFormGroup });
      });

      it('renders correct blocks', () => {
        expect(findIcon().exists()).toBe(false);
        expect(findDisabledInput().exists()).toBe(false);
        expect(findDropdown().exists()).toBe(true);
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
      isLoading: true,
    });

    expect(wrapper.findComponent(GlModal).props('actionPrimary').attributes.loading).toBe(true);
  });

  it('with invalidFeedbackMessage, set members form group exception state', () => {
    createComponent({
      invalidFeedbackMessage: 'invalid message!',
    });

    expect(findMembersFormGroup().props()).toEqual({
      invalidFeedback: 'invalid message!',
      state: false,
    });
  });
});

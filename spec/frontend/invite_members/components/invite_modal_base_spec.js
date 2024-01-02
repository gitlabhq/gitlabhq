import {
  GlCollapsibleListbox,
  GlDatepicker,
  GlFormGroup,
  GlLink,
  GlSprintf,
  GlModal,
  GlIcon,
} from '@gitlab/ui';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import {
  mountExtended,
  shallowMountExtended,
  extendedWrapper,
} from 'helpers/vue_test_utils_helper';
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
        GlModal: stubComponent(GlModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
        }),
        ...requiredStubs,
        ...stubs,
      },
    });
  };

  const findCollapsibleListbox = () => extendedWrapper(wrapper.findComponent(GlCollapsibleListbox));
  const findCollapsibleListboxOptions = () => findCollapsibleListbox().findAllByRole('option');
  const findDatepicker = () => wrapper.findComponent(GlDatepicker);
  const findLink = () => wrapper.findComponent(GlLink);
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

    describe('rendering the access levels dropdown', () => {
      beforeEach(() => {
        createComponent({
          props: { isLoadingRoles: true },
          mountFn: mountExtended,
        });
      });

      it('passes `isLoadingRoles` prop to the dropdown', () => {
        expect(findCollapsibleListbox().props('loading')).toBe(true);
      });

      it('sets the default dropdown text to the default access level name', () => {
        expect(findCollapsibleListbox().exists()).toBe(true);
        const option = findCollapsibleListbox().find('[aria-selected]');
        expect(option.text()).toBe('Reporter');
      });

      it('updates the selection base on changes in the dropdown', async () => {
        wrapper.setProps({ accessLevels: { validRoles: [] } });
        expect(findCollapsibleListbox().props('selected')).not.toHaveLength(0);
        await nextTick();

        expect(findCollapsibleListboxOptions()).toHaveLength(0);
        expect(findCollapsibleListbox().props('selected')).toHaveLength(0);
      });

      it('reset the dropdown to the default option', async () => {
        const developerOption = findCollapsibleListboxOptions().at(2);
        await developerOption.trigger('click');

        let option;
        option = findCollapsibleListbox().find('[aria-selected]');
        expect(option.text()).toBe('Developer');

        // Reset the dropdown by clicking cancel button
        await findCancelButton().trigger('click');

        option = findCollapsibleListbox().find('[aria-selected]');
        expect(option.text()).toBe('Reporter');
      });

      it('renders dropdown items for each accessLevel', () => {
        expect(findCollapsibleListboxOptions()).toHaveLength(5);
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
      const textRegex = /Select a role\s*Read more about role permissions\s*Access expiration date \(optional\)/;

      beforeEach(() => {
        createComponent({ props: { reachedLimit: false }, stubs: { GlModal, GlFormGroup } });
      });

      it('renders correct blocks', () => {
        expect(findIcon().exists()).toBe(false);
        expect(findDisabledInput().exists()).toBe(false);
        expect(findCollapsibleListbox().exists()).toBe(true);
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

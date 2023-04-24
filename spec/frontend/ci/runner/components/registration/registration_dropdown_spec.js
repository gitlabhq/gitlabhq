import { GlModal, GlDropdown, GlDropdownItem, GlDropdownForm, GlIcon } from '@gitlab/ui';
import { createWrapper } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import { s__ } from '~/locale';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import RegistrationDropdown from '~/ci/runner/components/registration/registration_dropdown.vue';
import RegistrationToken from '~/ci/runner/components/registration/registration_token.vue';
import RegistrationTokenResetDropdownItem from '~/ci/runner/components/registration/registration_token_reset_dropdown_item.vue';

import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/ci/runner/constants';

import getRunnerPlatformsQuery from '~/vue_shared/components/runner_instructions/graphql/get_runner_platforms.query.graphql';
import getRunnerSetupInstructionsQuery from '~/vue_shared/components/runner_instructions/graphql/get_runner_setup.query.graphql';

import {
  mockRunnerPlatforms,
  mockInstructions,
} from 'jest/vue_shared/components/runner_instructions/mock_data';
import { mockRegistrationToken } from '../../mock_data';

Vue.use(VueApollo);

describe('RegistrationDropdown', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownBtn = () => findDropdown().find('button');
  const findRegistrationInstructionsDropdownItem = () => wrapper.findComponent(GlDropdownItem);
  const findTokenDropdownItem = () => wrapper.findComponent(GlDropdownForm);
  const findRegistrationToken = () => wrapper.findComponent(RegistrationToken);
  const findRegistrationTokenInput = () =>
    wrapper.findByLabelText(RegistrationToken.i18n.registrationToken);
  const findTokenResetDropdownItem = () =>
    wrapper.findComponent(RegistrationTokenResetDropdownItem);
  const findModal = () => wrapper.findComponent(GlModal);
  const findModalContent = () =>
    createWrapper(document.body)
      .find('[data-testid="runner-instructions-modal"]')
      .text()
      .replace(/[\n\t\s]+/g, ' ');

  const openModal = async () => {
    await findRegistrationInstructionsDropdownItem().trigger('click');
    findModal().vm.$emit('shown');

    await waitForPromises();
  };

  const createComponent = ({ props = {}, ...options } = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(RegistrationDropdown, {
      propsData: {
        registrationToken: mockRegistrationToken,
        type: INSTANCE_TYPE,
        ...props,
      },
      ...options,
    });
  };

  const createComponentWithModal = () => {
    const requestHandlers = [
      [getRunnerPlatformsQuery, jest.fn().mockResolvedValue(mockRunnerPlatforms)],
      [getRunnerSetupInstructionsQuery, jest.fn().mockResolvedValue(mockInstructions)],
    ];

    createComponent(
      {
        // Mock load modal contents from API
        apolloProvider: createMockApollo(requestHandlers),
        // Use `attachTo` to find the modal
        attachTo: document.body,
      },
      mountExtended,
    );
  };

  it.each`
    type             | text
    ${INSTANCE_TYPE} | ${s__('Runners|Register an instance runner')}
    ${GROUP_TYPE}    | ${s__('Runners|Register a group runner')}
    ${PROJECT_TYPE}  | ${s__('Runners|Register a project runner')}
  `('Dropdown text for type $type is "$text"', () => {
    createComponent({ props: { type: INSTANCE_TYPE } }, mountExtended);

    expect(wrapper.text()).toContain('Register an instance runner');
  });

  it('Passes attributes to dropdown', () => {
    createComponent({ attrs: { right: true } });

    expect(findDropdown().attributes()).toMatchObject({ right: 'true' });
  });

  it('Passes default props and attributes to dropdown', () => {
    createComponent();

    expect(findDropdown().props()).toMatchObject({
      category: 'primary',
      variant: 'confirm',
    });

    expect(findDropdown().attributes()).toMatchObject({
      toggleclass: '',
    });
  });

  describe('Instructions dropdown item', () => {
    it('Displays "Show runner" dropdown item', () => {
      createComponent();

      expect(findRegistrationInstructionsDropdownItem().text()).toBe(
        'Show runner installation and registration instructions',
      );
    });

    describe('When the dropdown item is clicked', () => {
      beforeEach(async () => {
        createComponentWithModal({}, mountExtended);

        await openModal();
      });

      it('opens the modal with contents', () => {
        const modalText = findModalContent();

        expect(modalText).toContain('Install a runner');

        // Environment selector
        expect(modalText).toContain('Environment');
        expect(modalText).toContain('Linux macOS Windows Docker Kubernetes');

        // Architecture selector
        expect(modalText).toContain('Architecture');
        expect(modalText).toContain('amd64 amd64 386 arm arm64');

        expect(modalText).toContain('Download and install binary');
      });
    });
  });

  describe('Registration token', () => {
    it('Displays dropdown form for the registration token', () => {
      createComponent();

      expect(findTokenDropdownItem().exists()).toBe(true);
    });

    it('Displays masked value by default', () => {
      const mockToken = '0123456789';
      const maskToken = '**********';

      createComponent(
        {
          props: { registrationToken: mockToken },
        },
        mountExtended,
      );

      expect(findRegistrationTokenInput().element.value).toBe(maskToken);
    });
  });

  describe('Reset token item', () => {
    it('Displays registration token reset item', () => {
      createComponent();

      expect(findTokenResetDropdownItem().exists()).toBe(true);
    });

    it.each([INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE])('Set up token reset for %s', (type) => {
      createComponent({ props: { type } });

      expect(findTokenResetDropdownItem().props('type')).toBe(type);
    });
  });

  describe('When token is reset', () => {
    const newToken = 'mock1';

    const resetToken = async () => {
      findTokenResetDropdownItem().vm.$emit('tokenReset', newToken);
      await nextTick();
    };

    it('Updates token input', async () => {
      createComponent({}, mountExtended);

      expect(findRegistrationToken().props('value')).not.toBe(newToken);

      await resetToken();

      expect(findRegistrationToken().props('value')).toBe(newToken);
    });

    it('Updates token in modal', async () => {
      createComponentWithModal({}, mountExtended);

      await openModal();

      expect(findModalContent()).toContain(mockRegistrationToken);

      await resetToken();

      expect(findModalContent()).toContain(newToken);
    });
  });

  describe.each([
    { createRunnerWorkflowForAdmin: true },
    { createRunnerWorkflowForNamespace: true },
  ])('When showing a "deprecated" warning', (glFeatures) => {
    it('Passes deprecated variant props and attributes to dropdown', () => {
      createComponent({
        provide: { glFeatures },
      });

      expect(findDropdown().props()).toMatchObject({
        category: 'tertiary',
        variant: 'default',
        text: '',
      });

      expect(findDropdown().attributes()).toMatchObject({
        toggleclass: 'gl-px-3!',
      });
    });

    it('shows warning text', () => {
      createComponent(
        {
          provide: { glFeatures },
        },
        mountExtended,
      );

      const text = wrapper.findByText(s__('Runners|Support for registration tokens is deprecated'));

      expect(text.exists()).toBe(true);
    });

    it('button shows only ellipsis icon', () => {
      createComponent(
        {
          provide: { glFeatures },
        },
        mountExtended,
      );

      expect(findDropdownBtn().text()).toBe('');
      expect(findDropdownBtn().findComponent(GlIcon).props('name')).toBe('ellipsis_v');
      expect(findDropdownBtn().findAllComponents(GlIcon)).toHaveLength(1);
    });
  });
});

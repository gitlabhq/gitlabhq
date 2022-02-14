import { GlDropdown, GlDropdownItem, GlDropdownForm } from '@gitlab/ui';
import { mount, shallowMount, createWrapper } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';

import VueApollo from 'vue-apollo';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import RegistrationDropdown from '~/runner/components/registration/registration_dropdown.vue';
import RegistrationTokenResetDropdownItem from '~/runner/components/registration/registration_token_reset_dropdown_item.vue';

import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/runner/constants';

import getRunnerPlatformsQuery from '~/vue_shared/components/runner_instructions/graphql/queries/get_runner_platforms.query.graphql';
import getRunnerSetupInstructionsQuery from '~/vue_shared/components/runner_instructions/graphql/queries/get_runner_setup.query.graphql';

import {
  mockGraphqlRunnerPlatforms,
  mockGraphqlInstructions,
} from 'jest/vue_shared/components/runner_instructions/mock_data';

const mockToken = '0123456789';
const maskToken = '**********';

describe('RegistrationDropdown', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);

  const findRegistrationInstructionsDropdownItem = () => wrapper.findComponent(GlDropdownItem);
  const findTokenDropdownItem = () => wrapper.findComponent(GlDropdownForm);
  const findTokenResetDropdownItem = () =>
    wrapper.findComponent(RegistrationTokenResetDropdownItem);

  const findToggleMaskButton = () => wrapper.findByTestId('toggle-masked');

  const createComponent = ({ props = {}, ...options } = {}, mountFn = shallowMount) => {
    wrapper = extendedWrapper(
      mountFn(RegistrationDropdown, {
        propsData: {
          registrationToken: mockToken,
          type: INSTANCE_TYPE,
          ...props,
        },
        ...options,
      }),
    );
  };

  it.each`
    type             | text
    ${INSTANCE_TYPE} | ${'Register an instance runner'}
    ${GROUP_TYPE}    | ${'Register a group runner'}
    ${PROJECT_TYPE}  | ${'Register a project runner'}
  `('Dropdown text for type $type is "$text"', () => {
    createComponent({ props: { type: INSTANCE_TYPE } }, mount);

    expect(wrapper.text()).toContain('Register an instance runner');
  });

  it('Passes attributes to the dropdown component', () => {
    createComponent({ attrs: { right: true } });

    expect(findDropdown().attributes()).toMatchObject({ right: 'true' });
  });

  describe('Instructions dropdown item', () => {
    it('Displays "Show runner" dropdown item', () => {
      createComponent();

      expect(findRegistrationInstructionsDropdownItem().text()).toBe(
        'Show runner installation and registration instructions',
      );
    });

    describe('When the dropdown item is clicked', () => {
      Vue.use(VueApollo);

      const requestHandlers = [
        [getRunnerPlatformsQuery, jest.fn().mockResolvedValue(mockGraphqlRunnerPlatforms)],
        [getRunnerSetupInstructionsQuery, jest.fn().mockResolvedValue(mockGraphqlInstructions)],
      ];

      const findModalInBody = () =>
        createWrapper(document.body).find('[data-testid="runner-instructions-modal"]');

      beforeEach(async () => {
        createComponent(
          {
            // Mock load modal contents from API
            apolloProvider: createMockApollo(requestHandlers),
            // Use `attachTo` to find the modal
            attachTo: document.body,
          },
          mount,
        );

        await findRegistrationInstructionsDropdownItem().trigger('click');
        await waitForPromises();
      });

      afterEach(() => {
        wrapper.destroy();
      });

      it('opens the modal with contents', () => {
        const modalText = findModalInBody()
          .text()
          .replace(/[\n\t\s]+/g, ' ');

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
      createComponent({}, mount);

      expect(findTokenDropdownItem().text()).toMatchInterpolatedText(
        `Registration token ${maskToken}`,
      );
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

  it('Updates the token when it gets reset', async () => {
    createComponent({}, mount);

    const newToken = 'mock1';

    findTokenResetDropdownItem().vm.$emit('tokenReset', newToken);
    findToggleMaskButton().vm.$emit('click', { stopPropagation: jest.fn() });
    await nextTick();

    expect(findTokenDropdownItem().text()).toMatchInterpolatedText(
      `Registration token ${newToken}`,
    );
  });
});

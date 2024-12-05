import {
  GlModal,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDropdownForm,
  GlIcon,
} from '@gitlab/ui';
import { createWrapper } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import RegistrationDropdown from '~/ci/runner/components/registration/registration_dropdown.vue';
import RegistrationToken from '~/ci/runner/components/registration/registration_token.vue';
import RegistrationTokenResetDropdownItem from '~/ci/runner/components/registration/registration_token_reset_dropdown_item.vue';

import {
  INSTANCE_TYPE,
  GROUP_TYPE,
  PROJECT_TYPE,
  I18N_REGISTER_INSTANCE_TYPE,
  I18N_REGISTER_GROUP_TYPE,
  I18N_REGISTER_PROJECT_TYPE,
} from '~/ci/runner/constants';

import getRunnerPlatformsQuery from '~/ci/runner/components/registration/runner_instructions/graphql/get_runner_platforms.query.graphql';
import getRunnerSetupInstructionsQuery from '~/ci/runner/components/registration/runner_instructions/graphql/get_runner_setup.query.graphql';

import { mockRegistrationToken } from '../../mock_data';
import { mockRunnerPlatforms, mockInstructions } from './runner_instructions/mock_data';

Vue.use(VueApollo);

describe('RegistrationDropdown', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownBtn = () => findDropdown().find('button');
  const findRegistrationInstructionsDropdownItem = () =>
    wrapper.findComponent(GlDisclosureDropdownItem);
  const findTokenDropdownItem = () => wrapper.findComponent(GlDropdownForm);
  const findRegistrationToken = () => wrapper.findComponent(RegistrationToken);
  const findRegistrationTokenInput = () =>
    wrapper.findByLabelText(`Registration token Support for registration tokens is deprecated`);
  const findTokenResetDropdownItem = () =>
    wrapper.findComponent(RegistrationTokenResetDropdownItem);
  const findModal = () => wrapper.findComponent(GlModal);
  const findModalContent = () =>
    createWrapper(document.body)
      .find('[data-testid="runner-instructions-modal"]')
      .text()
      .replace(/[\n\t\s]+/g, ' ');

  const openModal = async () => {
    await findRegistrationInstructionsDropdownItem().vm.$emit('action');
    findModal().vm.$emit('shown');
    await waitForPromises();
  };

  const createComponent = ({ props = {}, ...options } = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(RegistrationDropdown, {
      propsData: {
        type: INSTANCE_TYPE,
        ...props,
      },
      stubs: {
        GlDisclosureDropdownItem,
      },
      ...options,
    });
  };

  const createComponentWithModal = (options = {}) => {
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
        ...options,
      },
      mountExtended,
    );
  };

  describe('when registration token is disabled', () => {
    beforeEach(() => {
      createComponent(
        { props: { allowRegistrationToken: false, registrationToken: null } },
        mountExtended,
      );
    });

    it('"token is disabled" text is shown', () => {
      expect(wrapper.text()).toContain(
        'Creating runners with runner registration tokens is disabled',
      );
    });

    it('registration token is not shown', () => {
      expect(findRegistrationToken().exists()).toBe(false);
    });
  });

  describe('when registration token is enabled', () => {
    it.each`
      type             | text
      ${INSTANCE_TYPE} | ${I18N_REGISTER_INSTANCE_TYPE}
      ${GROUP_TYPE}    | ${I18N_REGISTER_GROUP_TYPE}
      ${PROJECT_TYPE}  | ${I18N_REGISTER_PROJECT_TYPE}
    `('Dropdown text for type $type is "$text"', ({ type, text }) => {
      createComponent(
        {
          props: {
            allowRegistrationToken: true,
            registrationToken: mockRegistrationToken,
            type,
          },
        },
        mountExtended,
      );

      expect(wrapper.text()).toContain(text);
    });

    it('Passes attributes to dropdown', () => {
      createComponent({
        props: {
          allowRegistrationToken: true,
          registrationToken: mockRegistrationToken,
        },
        attrs: { right: true },
      });

      expect(findDropdown().attributes()).toMatchObject({ right: 'true' });
    });

    it('Passes default props and attributes to dropdown', () => {
      createComponent({
        props: {
          allowRegistrationToken: true,
          registrationToken: mockRegistrationToken,
        },
      });

      expect(findDropdown().props()).toMatchObject({
        category: 'tertiary',
        variant: 'default',
      });

      expect(findDropdown().attributes()).toMatchObject({
        toggleclass: '!gl-px-3',
      });
    });

    describe('Instructions dropdown item', () => {
      it('Displays "Show runner" dropdown item', () => {
        createComponent({
          props: {
            allowRegistrationToken: true,
            registrationToken: mockRegistrationToken,
          },
        });

        expect(findRegistrationInstructionsDropdownItem().text()).toBe(
          'Show runner installation and registration instructions',
        );
      });

      describe('When the dropdown item is clicked', () => {
        beforeEach(async () => {
          createComponentWithModal(
            {
              props: {
                allowRegistrationToken: true,
                registrationToken: mockRegistrationToken,
              },
            },
            mountExtended,
          );

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
        createComponent({
          props: {
            allowRegistrationToken: true,
            registrationToken: mockRegistrationToken,
          },
        });

        expect(findTokenDropdownItem().exists()).toBe(true);
      });

      it('Displays masked value as password input by default', () => {
        const mockToken = '0123456789';

        createComponent(
          {
            props: { allowRegistrationToken: true, registrationToken: mockToken },
          },
          mountExtended,
        );

        expect(findRegistrationTokenInput().classes()).toContain('input-copy-show-disc');
      });
    });

    describe('Reset token item', () => {
      describe.each([INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE])(
        'Set up token reset for %s',
        (type) => {
          beforeEach(() => {
            createComponent({
              props: {
                allowRegistrationToken: true,
                registrationToken: mockRegistrationToken,
                type,
              },
            });
          });

          it('Displays registration token reset item', () => {
            expect(findTokenResetDropdownItem().props('type')).toBe(type);
          });
        },
      );
    });

    describe('When token is reset', () => {
      const newToken = 'mock1';

      const resetToken = async () => {
        findTokenResetDropdownItem().vm.$emit('tokenReset', newToken);
        await nextTick();
      };

      it('Updates token input', async () => {
        createComponent(
          { props: { allowRegistrationToken: true, registrationToken: mockRegistrationToken } },
          mountExtended,
        );

        expect(findRegistrationToken().props('value')).not.toBe(newToken);

        await resetToken();

        expect(findRegistrationToken().props('value')).toBe(newToken);
      });

      it('Updates token in modal', async () => {
        createComponentWithModal(
          { props: { allowRegistrationToken: true, registrationToken: mockRegistrationToken } },
          mountExtended,
        );

        await openModal();

        expect(findModalContent()).toContain(mockRegistrationToken);

        await resetToken();

        expect(findModalContent()).toContain(newToken);
      });
    });

    describe('When showing a "deprecated" warning', () => {
      it('passes deprecated variant props and attributes to dropdown', () => {
        createComponent({
          props: { allowRegistrationToken: true, registrationToken: mockRegistrationToken },
        });

        expect(findDropdown().props()).toMatchObject({
          category: 'tertiary',
          variant: 'default',
          toggleText: I18N_REGISTER_INSTANCE_TYPE,
          textSrOnly: true,
        });

        expect(findDropdown().attributes()).toMatchObject({
          toggleclass: '!gl-px-3',
        });
      });

      it.each`
        type             | text
        ${INSTANCE_TYPE} | ${I18N_REGISTER_INSTANCE_TYPE}
        ${GROUP_TYPE}    | ${I18N_REGISTER_GROUP_TYPE}
        ${PROJECT_TYPE}  | ${I18N_REGISTER_PROJECT_TYPE}
      `('dropdown text for type $type is "$text"', ({ type, text }) => {
        createComponent({ props: { type } }, mountExtended);

        expect(wrapper.text()).toContain(text);
      });

      it('shows warning text', () => {
        createComponent(
          {
            props: {
              allowRegistrationToken: true,
              registrationToken: mockRegistrationToken,
            },
          },
          mountExtended,
        );

        const text = wrapper.findByText('Support for registration tokens is deprecated');
        expect(text.exists()).toBe(true);
      });

      it('button shows ellipsis icon', () => {
        createComponent(
          { props: { allowRegistrationToken: true, registrationToken: mockRegistrationToken } },
          mountExtended,
        );

        expect(findDropdownBtn().findComponent(GlIcon).props('name')).toBe('ellipsis_v');
        expect(findDropdownBtn().findAllComponents(GlIcon)).toHaveLength(1);
      });
    });
  });

  describe('when registration token is hidden due to user permissions', () => {
    beforeEach(() => {
      createComponent({ props: { allowRegistrationToken: true, registrationToken: null } });
    });

    it('the component is not shown', () => {
      expect(wrapper.find('*').exists()).toBe(false);
    });
  });
});

import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlForm } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ContainerProtectionRuleForm from '~/packages_and_registries/settings/project/components/container_protection_rule_form.vue';
import createContainerProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/create_container_protection_rule.mutation.graphql';
import {
  createContainerProtectionRuleMutationPayload,
  createContainerProtectionRuleMutationInput,
  createContainerProtectionRuleMutationPayloadErrors,
} from '../mock_data';

Vue.use(VueApollo);

describe('container Protection Rule Form', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findRepositoryPathPatternInput = () =>
    wrapper.findByRole('textbox', { name: /repository path pattern/i });
  const findPushProtectedUpToAccessLevelSelect = () =>
    wrapper.findByRole('combobox', { name: /maximum access level prevented from pushing/i });
  const findDeleteProtectedUpToAccessLevelSelect = () =>
    wrapper.findByRole('combobox', { name: /maximum access level prevented from deleting/i });
  const findSubmitButton = () => wrapper.findByRole('button', { name: /add rule/i });

  const mountComponent = ({ config, provide = defaultProvidedValues } = {}) => {
    wrapper = mountExtended(ContainerProtectionRuleForm, {
      provide,
      ...config,
    });
  };

  const mountComponentWithApollo = ({ provide = defaultProvidedValues, mutationResolver } = {}) => {
    const requestHandlers = [[createContainerProtectionRuleMutation, mutationResolver]];

    fakeApollo = createMockApollo(requestHandlers);

    mountComponent({
      provide,
      config: {
        apolloProvider: fakeApollo,
      },
    });
  };

  describe('form fields', () => {
    describe('form field "pushProtectedUpToAccessLevelSelect"', () => {
      const pushProtectedUpToAccessLevelSelectOptions = () =>
        findPushProtectedUpToAccessLevelSelect()
          .findAll('option')
          .wrappers.map((option) => option.element.value);

      it.each(['DEVELOPER', 'MAINTAINER', 'OWNER'])(
        'includes the %s access level',
        (accessLevel) => {
          mountComponent();

          expect(findPushProtectedUpToAccessLevelSelect().exists()).toBe(true);
          expect(pushProtectedUpToAccessLevelSelectOptions()).toContain(accessLevel);
        },
      );
    });

    describe('when graphql mutation is in progress', () => {
      beforeEach(() => {
        mountComponentWithApollo();

        findForm().trigger('submit');
      });

      it('disables all form fields', () => {
        expect(findSubmitButton().props('disabled')).toBe(true);
        expect(findRepositoryPathPatternInput().attributes('disabled')).toBe('disabled');
        expect(findPushProtectedUpToAccessLevelSelect().attributes('disabled')).toBe('disabled');
        expect(findDeleteProtectedUpToAccessLevelSelect().attributes('disabled')).toBe('disabled');
      });

      it('displays a loading spinner', () => {
        expect(findSubmitButton().props('loading')).toBe(true);
      });
    });
  });

  describe('form actions', () => {
    describe('button "Protect"', () => {
      it.each`
        repositoryPathPattern                                               | submitButtonDisabled
        ${''}                                                               | ${true}
        ${' '}                                                              | ${true}
        ${createContainerProtectionRuleMutationInput.repositoryPathPattern} | ${false}
      `(
        'when repositoryPathPattern is "$repositoryPathPattern" then the disabled state of the submit button is $submitButtonDisabled',
        async ({ repositoryPathPattern, submitButtonDisabled }) => {
          mountComponent();

          expect(findSubmitButton().props('disabled')).toBe(true);

          await findRepositoryPathPatternInput().setValue(repositoryPathPattern);

          expect(findSubmitButton().props('disabled')).toBe(submitButtonDisabled);
        },
      );
    });
  });

  describe('form events', () => {
    describe('reset', () => {
      const mutationResolver = jest
        .fn()
        .mockResolvedValue(createContainerProtectionRuleMutationPayload());

      beforeEach(() => {
        mountComponentWithApollo({ mutationResolver });

        findForm().trigger('reset');
      });

      it('emits custom event "cancel"', () => {
        expect(mutationResolver).not.toHaveBeenCalled();

        expect(wrapper.emitted('cancel')).toBeDefined();
        expect(wrapper.emitted('cancel')[0]).toEqual([]);
      });

      it('does not dispatch apollo mutation request', () => {
        expect(mutationResolver).not.toHaveBeenCalled();
      });

      it('does not emit custom event "submit"', () => {
        expect(wrapper.emitted()).not.toHaveProperty('submit');
      });
    });

    describe('submit', () => {
      const findAlert = () => wrapper.findByRole('alert');

      const submitForm = () => {
        findForm().trigger('submit');
        return waitForPromises();
      };

      it('dispatches correct apollo mutation', async () => {
        const mutationResolver = jest
          .fn()
          .mockResolvedValue(createContainerProtectionRuleMutationPayload());

        mountComponentWithApollo({ mutationResolver });

        await findRepositoryPathPatternInput().setValue(
          createContainerProtectionRuleMutationInput.repositoryPathPattern,
        );

        await submitForm();

        expect(mutationResolver).toHaveBeenCalledWith({
          input: { projectPath: 'path', ...createContainerProtectionRuleMutationInput },
        });
      });

      it('emits event "submit" when apollo mutation successful', async () => {
        const mutationResolver = jest
          .fn()
          .mockResolvedValue(createContainerProtectionRuleMutationPayload());

        mountComponentWithApollo({ mutationResolver });

        await submitForm();

        expect(wrapper.emitted('submit')).toBeDefined();
        const expectedEventSubmitPayload = createContainerProtectionRuleMutationPayload().data
          .createContainerRegistryProtectionRule.containerRegistryProtectionRule;
        expect(wrapper.emitted('submit')[0]).toEqual([expectedEventSubmitPayload]);

        expect(wrapper.emitted()).not.toHaveProperty('cancel');
      });

      it('shows error alert with general message when apollo mutation request responds with errors', async () => {
        mountComponentWithApollo({
          mutationResolver: jest.fn().mockResolvedValue(
            createContainerProtectionRuleMutationPayload({
              errors: createContainerProtectionRuleMutationPayloadErrors,
            }),
          ),
        });

        await submitForm();

        expect(findAlert().isVisible()).toBe(true);
        expect(findAlert().text()).toBe(createContainerProtectionRuleMutationPayloadErrors[0]);
      });

      it('shows error alert with general message when apollo mutation request fails', async () => {
        mountComponentWithApollo({
          mutationResolver: jest.fn().mockRejectedValue(new Error('GraphQL error')),
        });

        await submitForm();

        expect(findAlert().isVisible()).toBe(true);
        expect(findAlert().text()).toBe('Something went wrong while saving the protection rule.');
      });
    });
  });
});

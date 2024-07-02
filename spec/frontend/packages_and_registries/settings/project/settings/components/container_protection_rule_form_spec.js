import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlForm } from '@gitlab/ui';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
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
  const findMinimumAccessLevelForPushSelect = () =>
    wrapper.findByRole('combobox', { name: /minimum access level for push/i });
  const findMinimumAccessLevelForDeleteSelect = () =>
    wrapper.findByRole('combobox', { name: /minimum access level for delete/i });
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
    describe('form field "minimumAccessLevelForPush"', () => {
      const minimumAccessLevelForPushOptions = () =>
        findMinimumAccessLevelForPushSelect()
          .findAll('option')
          .wrappers.map((option) => option.element.value);

      it.each(['', 'MAINTAINER', 'OWNER', 'ADMIN'])(
        'includes the access level "%s" as an option',
        (accessLevel) => {
          mountComponent();

          expect(findMinimumAccessLevelForPushSelect().exists()).toBe(true);
          expect(minimumAccessLevelForPushOptions()).toContain(accessLevel);
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
        expect(findMinimumAccessLevelForPushSelect().attributes('disabled')).toBe('disabled');
        expect(findMinimumAccessLevelForDeleteSelect().attributes('disabled')).toBe('disabled');
      });

      it('displays a loading spinner', () => {
        expect(findSubmitButton().props('loading')).toBe(true);
      });
    });
  });

  describe('form actions', () => {
    describe('button "Add rule"', () => {
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
      const findAlert = () => extendedWrapper(wrapper.findByRole('alert'));

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

      it('dispatches correct apollo mutation when no minimumAccessLevelForPush is selected', async () => {
        const mutationResolver = jest
          .fn()
          .mockResolvedValue(createContainerProtectionRuleMutationPayload());

        mountComponentWithApollo({ mutationResolver });

        await findRepositoryPathPatternInput().setValue(
          createContainerProtectionRuleMutationInput.repositoryPathPattern,
        );
        await findMinimumAccessLevelForPushSelect().setValue('');

        await submitForm();

        expect(mutationResolver).toHaveBeenCalledWith({
          input: {
            projectPath: 'path',
            ...createContainerProtectionRuleMutationInput,
            minimumAccessLevelForPush: null,
          },
        });
      });

      it('emits event "submit" when apollo mutation successful', async () => {
        const mutationResolver = jest
          .fn()
          .mockResolvedValue(createContainerProtectionRuleMutationPayload());

        mountComponentWithApollo({ mutationResolver });

        await submitForm();

        expect(wrapper.emitted('submit')).toBeDefined();
        const expectedEventSubmitPayload =
          createContainerProtectionRuleMutationPayload().data.createContainerRegistryProtectionRule
            .containerRegistryProtectionRule;
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

        expect(
          findAlert().findByText(createContainerProtectionRuleMutationPayloadErrors[0]).exists(),
        ).toBe(true);
        expect(
          findAlert().findByText(createContainerProtectionRuleMutationPayloadErrors[1]).exists(),
        ).toBe(true);
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

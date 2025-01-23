import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlForm } from '@gitlab/ui';

import createContainerProtectionTagRuleMutationPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/mutations/create_container_protection_tag_rule.mutation.graphql.json';
import createContainerProtectionTagRuleMutationErrorPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/mutations/create_container_protection_tag_rule.mutation.graphql.errors.json';
import createContainerProtectionTagRuleMutationServerErrorPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/mutations/create_container_protection_tag_rule.mutation.graphql.server_errors.json';

import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ContainerProtectionTagRuleForm from '~/packages_and_registries/settings/project/components/container_protection_tag_rule_form.vue';
import createContainerProtectionTagRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/create_container_protection_tag_rule.mutation.graphql';

import { createContainerProtectionTagRuleMutationInput } from '../mock_data';

Vue.use(VueApollo);

describe('container Protection Rule Form', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findTagNamePatternInput = () =>
    wrapper.findByRole('textbox', { name: /protect container tags matching/i });
  const findMinimumAccessLevelForPushSelect = () =>
    wrapper.findByRole('combobox', { name: /minimum role allowed to push/i });
  const findMinimumAccessLevelForDeleteSelect = () =>
    wrapper.findByRole('combobox', { name: /minimum role allowed to delete/i });
  const findSubmitButton = () => wrapper.findByTestId('add-rule-btn');

  const mountComponent = ({ config, provide = defaultProvidedValues } = {}) => {
    wrapper = mountExtended(ContainerProtectionTagRuleForm, {
      provide,
      ...config,
    });
  };

  const mountComponentWithApollo = ({
    provide = defaultProvidedValues,
    mutationResolver = jest.fn().mockResolvedValue(createContainerProtectionTagRuleMutationPayload),
  } = {}) => {
    const requestHandlers = [[createContainerProtectionTagRuleMutation, mutationResolver]];

    fakeApollo = createMockApollo(requestHandlers);

    mountComponent({
      provide,
      config: {
        apolloProvider: fakeApollo,
      },
    });
  };

  describe('form fields', () => {
    describe('form field "tagNamePattern"', () => {
      it('exists', () => {
        mountComponent();

        expect(findTagNamePatternInput().exists()).toBe(true);
      });

      describe.each`
        tagNamePattern                                                              | errorMessage
        ${''}                                                                       | ${'This field is required.'}
        ${' '}                                                                      | ${'This field is required.'}
        ${createContainerProtectionTagRuleMutationInput.tagNamePattern.repeat(100)} | ${'Must be less than 100 characters.'}
      `('when tagNamePattern is "$tagNamePattern"', ({ tagNamePattern, errorMessage }) => {
        const mutationResolver = jest
          .fn()
          .mockResolvedValue(createContainerProtectionTagRuleMutationPayload);

        beforeEach(async () => {
          mountComponentWithApollo({
            mutationResolver,
          });

          await findTagNamePatternInput().setValue(tagNamePattern);
        });

        it(`then error message is ${errorMessage}`, () => {
          expect(wrapper.findByText(errorMessage).exists()).toBe(true);
        });

        it('when submitted does not make graphql request', async () => {
          await findForm().trigger('submit');

          expect(mutationResolver).not.toHaveBeenCalled();
        });
      });
    });

    describe('form field "minimumAccessLevelForPush"', () => {
      const minimumAccessLevelForPushOptions = () =>
        findMinimumAccessLevelForPushSelect()
          .findAll('option')
          .wrappers.map((option) => option.element.value);

      it.each(['MAINTAINER', 'OWNER', 'ADMIN'])(
        'includes the access level "%s" as an option',
        (accessLevel) => {
          mountComponent();

          expect(findMinimumAccessLevelForPushSelect().exists()).toBe(true);
          expect(minimumAccessLevelForPushOptions()).toContain(accessLevel);
        },
      );
    });

    describe('form field "minimumAccessLevelForDelete"', () => {
      const minimumAccessLevelForDeleteOptions = () =>
        findMinimumAccessLevelForDeleteSelect()
          .findAll('option')
          .wrappers.map((option) => option.element.value);

      it.each(['MAINTAINER', 'OWNER', 'ADMIN'])(
        'includes the access level "%s" as an option',
        (accessLevel) => {
          mountComponent();

          expect(findMinimumAccessLevelForDeleteSelect().exists()).toBe(true);
          expect(minimumAccessLevelForDeleteOptions()).toContain(accessLevel);
        },
      );
    });

    describe('when graphql mutation is in progress', () => {
      beforeEach(async () => {
        mountComponentWithApollo();

        await findTagNamePatternInput().setValue(
          createContainerProtectionTagRuleMutationInput.tagNamePattern,
        );
        findForm().trigger('submit');
      });

      it('displays a loading spinner', () => {
        expect(findSubmitButton().props('loading')).toBe(true);
      });
    });
  });

  describe('form events', () => {
    describe('reset', () => {
      const mutationResolver = jest
        .fn()
        .mockResolvedValue(createContainerProtectionTagRuleMutationPayload);

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
        findTagNamePatternInput().setValue(
          createContainerProtectionTagRuleMutationInput.tagNamePattern,
        );
        findForm().trigger('submit');
        return waitForPromises();
      };

      it('dispatches correct apollo mutation', async () => {
        const mutationResolver = jest
          .fn()
          .mockResolvedValue(createContainerProtectionTagRuleMutationPayload);

        mountComponentWithApollo({ mutationResolver });

        await submitForm();

        expect(mutationResolver).toHaveBeenCalledWith({
          input: { projectPath: 'path', ...createContainerProtectionTagRuleMutationInput },
        });
      });

      it('emits event "submit" when apollo mutation successful', async () => {
        mountComponentWithApollo();

        await submitForm();

        expect(wrapper.emitted('submit')).toBeDefined();
        const expectedEventSubmitPayload =
          createContainerProtectionTagRuleMutationPayload.data.createContainerProtectionTagRule
            .containerProtectionTagRule;
        expect(wrapper.emitted('submit')[0]).toEqual([expectedEventSubmitPayload]);

        expect(wrapper.emitted()).not.toHaveProperty('cancel');
      });

      describe.each`
        description                      | mutationResolver                                                                           | expectedErrorMessage
        ${'responds with field errors'}  | ${jest.fn().mockResolvedValue(createContainerProtectionTagRuleMutationErrorPayload)}       | ${'Tag name pattern has already been taken'}
        ${'responds with server errors'} | ${jest.fn().mockResolvedValue(createContainerProtectionTagRuleMutationServerErrorPayload)} | ${"tagNamePattern can't be blank"}
        ${'fails with network error'}    | ${jest.fn().mockRejectedValue(new Error('GraphQL error'))}                                 | ${'Something went wrong while saving the protection rule.'}
      `(
        'when apollo mutation request $description',
        ({ mutationResolver, expectedErrorMessage }) => {
          beforeEach(async () => {
            mountComponentWithApollo({
              mutationResolver,
            });

            await submitForm();
          });

          it('shows error alert with correct message', () => {
            expect(findAlert().text()).toBe(expectedErrorMessage);
          });
        },
      );
    });
  });
});

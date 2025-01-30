import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlForm } from '@gitlab/ui';

import createContainerProtectionTagRuleMutationPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/mutations/create_container_protection_tag_rule.mutation.graphql.json';
import createContainerProtectionTagRuleMutationErrorPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/mutations/create_container_protection_tag_rule.mutation.graphql.errors.json';
import createContainerProtectionTagRuleMutationServerErrorPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/mutations/create_container_protection_tag_rule.mutation.graphql.server_errors.json';
import updateContainerProtectionTagRuleMutationPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/mutations/update_container_protection_tag_rule.mutation.graphql.json';
import updateContainerProtectionTagRuleMutationErrorPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/mutations/update_container_protection_tag_rule.mutation.graphql.errors.json';
import updateContainerProtectionTagRuleMutationServerErrorPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/mutations/update_container_protection_tag_rule.mutation.graphql.server_errors.json';

import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ContainerProtectionTagRuleForm from '~/packages_and_registries/settings/project/components/container_protection_tag_rule_form.vue';
import createContainerProtectionTagRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/create_container_protection_tag_rule.mutation.graphql';
import updateContainerProtectionTagRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_container_protection_tag_rule.mutation.graphql';

import { containerProtectionTagRuleMutationInput } from '../mock_data';

Vue.use(VueApollo);

describe('container Protection Rule Form', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
  };

  const rule =
    createContainerProtectionTagRuleMutationPayload.data.createContainerProtectionTagRule
      .containerProtectionTagRule;

  const findForm = () => wrapper.findComponent(GlForm);
  const findTagNamePatternInput = () =>
    wrapper.findByRole('textbox', { name: /protect container tags matching/i });
  const findMinimumAccessLevelForPushSelect = () =>
    wrapper.findByRole('combobox', { name: /minimum role allowed to push/i });
  const findMinimumAccessLevelForDeleteSelect = () =>
    wrapper.findByRole('combobox', { name: /minimum role allowed to delete/i });
  const findCancelButton = () => wrapper.findByRole('button', { name: /cancel/i });
  const findSubmitButton = () => wrapper.findByTestId('submit-btn');

  const mountComponent = ({ config, provide = defaultProvidedValues, props } = {}) => {
    wrapper = mountExtended(ContainerProtectionTagRuleForm, {
      propsData: props,
      provide,
      ...config,
    });
  };

  const mountComponentWithApollo = ({
    props = {},
    provide = defaultProvidedValues,
    createMutationResolver = jest
      .fn()
      .mockResolvedValue(createContainerProtectionTagRuleMutationPayload),
    updateMutationResolver = jest
      .fn()
      .mockResolvedValue(updateContainerProtectionTagRuleMutationPayload),
  } = {}) => {
    const requestHandlers = [
      [createContainerProtectionTagRuleMutation, createMutationResolver],
      [updateContainerProtectionTagRuleMutation, updateMutationResolver],
    ];

    fakeApollo = createMockApollo(requestHandlers);

    mountComponent({
      props,
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
        tagNamePattern                                                        | errorMessage
        ${''}                                                                 | ${'This field is required.'}
        ${' '}                                                                | ${'This field is required.'}
        ${containerProtectionTagRuleMutationInput.tagNamePattern.repeat(100)} | ${'Must be less than 100 characters.'}
      `('when tagNamePattern is "$tagNamePattern"', ({ tagNamePattern, errorMessage }) => {
        const createMutationResolver = jest
          .fn()
          .mockResolvedValue(createContainerProtectionTagRuleMutationPayload);

        beforeEach(async () => {
          mountComponentWithApollo({
            createMutationResolver,
          });

          await findTagNamePatternInput().setValue(tagNamePattern);
        });

        it(`then error message is ${errorMessage}`, () => {
          expect(wrapper.findByText(errorMessage).exists()).toBe(true);
        });

        it('when submitted does not make graphql request', async () => {
          await findForm().trigger('submit');

          expect(createMutationResolver).not.toHaveBeenCalled();
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
          containerProtectionTagRuleMutationInput.tagNamePattern,
        );
        findForm().trigger('submit');
      });

      it('displays a loading spinner', () => {
        expect(findSubmitButton().props('loading')).toBe(true);
      });
    });
  });

  describe.each`
    description                       | props       | submitButtonText
    ${'when form has no prop "rule"'} | ${{}}       | ${'Add rule'}
    ${'when form has prop "rule"'}    | ${{ rule }} | ${'Save changes'}
  `('$description', ({ props, submitButtonText }) => {
    beforeEach(() => {
      mountComponent({
        props,
      });
    });

    describe('submit button', () => {
      it(`renders text: ${submitButtonText}`, () => {
        expect(findSubmitButton().text()).toBe(submitButtonText);
      });
    });

    describe('cancel button', () => {
      it('renders with text: "Cancel"', () => {
        expect(findCancelButton().text()).toBe('Cancel');
      });
    });
  });

  describe('form events', () => {
    describe('reset', () => {
      const createMutationResolver = jest
        .fn()
        .mockResolvedValue(createContainerProtectionTagRuleMutationPayload);

      beforeEach(() => {
        mountComponentWithApollo({ createMutationResolver });

        findForm().trigger('reset');
      });

      it('emits custom event "cancel"', () => {
        expect(createMutationResolver).not.toHaveBeenCalled();

        expect(wrapper.emitted('cancel')).toBeDefined();
        expect(wrapper.emitted('cancel')[0]).toEqual([]);
      });

      it('does not dispatch apollo mutation request', () => {
        expect(createMutationResolver).not.toHaveBeenCalled();
      });

      it('does not emit custom event "submit"', () => {
        expect(wrapper.emitted()).not.toHaveProperty('submit');
      });
    });

    describe('submit a new rule', () => {
      const findAlert = () => extendedWrapper(wrapper.findByRole('alert'));

      const submitForm = () => {
        findTagNamePatternInput().setValue(containerProtectionTagRuleMutationInput.tagNamePattern);
        findForm().trigger('submit');
        return waitForPromises();
      };

      it('dispatches correct apollo mutation', async () => {
        const createMutationResolver = jest
          .fn()
          .mockResolvedValue(createContainerProtectionTagRuleMutationPayload);
        const updateMutationResolver = jest
          .fn()
          .mockResolvedValue(updateContainerProtectionTagRuleMutationPayload);

        mountComponentWithApollo({ createMutationResolver, updateMutationResolver });

        await submitForm();

        expect(createMutationResolver).toHaveBeenCalledWith({
          input: { projectPath: 'path', ...containerProtectionTagRuleMutationInput },
        });
        expect(updateMutationResolver).not.toHaveBeenCalled();
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
        description                      | createMutationResolver                                                                     | expectedErrorMessage
        ${'responds with field errors'}  | ${jest.fn().mockResolvedValue(createContainerProtectionTagRuleMutationErrorPayload)}       | ${'Tag name pattern has already been taken'}
        ${'responds with server errors'} | ${jest.fn().mockResolvedValue(createContainerProtectionTagRuleMutationServerErrorPayload)} | ${"tagNamePattern can't be blank"}
        ${'fails with network error'}    | ${jest.fn().mockRejectedValue(new Error('GraphQL error'))}                                 | ${'Something went wrong while saving the protection rule.'}
      `(
        'when apollo mutation request $description',
        ({ createMutationResolver, expectedErrorMessage }) => {
          beforeEach(async () => {
            mountComponentWithApollo({
              createMutationResolver,
            });

            await submitForm();
          });

          it('shows error alert with correct message', () => {
            expect(findAlert().text()).toBe(expectedErrorMessage);
          });
        },
      );
    });

    describe('updating existing rule', () => {
      const findAlert = () => extendedWrapper(wrapper.findByRole('alert'));
      const findDeleteCombobox = () => extendedWrapper(findMinimumAccessLevelForDeleteSelect());

      const submitForm = async () => {
        findTagNamePatternInput().setValue(containerProtectionTagRuleMutationInput.tagNamePattern);
        await findDeleteCombobox().findAll('option').at(0).setSelected();
        findForm().trigger('submit');
        return waitForPromises();
      };

      it('dispatches correct apollo mutation', async () => {
        const createMutationResolver = jest
          .fn()
          .mockResolvedValue(createContainerProtectionTagRuleMutationPayload);
        const updateMutationResolver = jest
          .fn()
          .mockResolvedValue(updateContainerProtectionTagRuleMutationPayload);

        mountComponentWithApollo({
          createMutationResolver,
          updateMutationResolver,
          props: { rule },
        });

        await submitForm();

        expect(createMutationResolver).not.toHaveBeenCalled();
        expect(updateMutationResolver).toHaveBeenCalledWith({
          input: { id: rule.id, ...containerProtectionTagRuleMutationInput },
        });
      });

      it('emits event "submit" when apollo mutation successful', async () => {
        mountComponentWithApollo({
          props: { rule },
        });

        await submitForm();

        expect(wrapper.emitted('submit')).toBeDefined();
        const expectedEventSubmitPayload =
          updateContainerProtectionTagRuleMutationPayload.data.updateContainerProtectionTagRule
            .containerProtectionTagRule;
        expect(wrapper.emitted('submit')[0]).toEqual([expectedEventSubmitPayload]);

        expect(wrapper.emitted()).not.toHaveProperty('cancel');
      });

      describe.each`
        description                      | updateMutationResolver                                                                     | expectedErrorMessage
        ${'responds with field errors'}  | ${jest.fn().mockResolvedValue(updateContainerProtectionTagRuleMutationErrorPayload)}       | ${'Tag name pattern has already been taken'}
        ${'responds with server errors'} | ${jest.fn().mockResolvedValue(updateContainerProtectionTagRuleMutationServerErrorPayload)} | ${"tagNamePattern can't be blank"}
        ${'fails with network error'}    | ${jest.fn().mockRejectedValue(new Error('GraphQL error'))}                                 | ${'Something went wrong while saving the protection rule.'}
      `(
        'when apollo mutation request $description',
        ({ updateMutationResolver, expectedErrorMessage }) => {
          beforeEach(async () => {
            mountComponentWithApollo({
              props: { rule },
              updateMutationResolver,
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

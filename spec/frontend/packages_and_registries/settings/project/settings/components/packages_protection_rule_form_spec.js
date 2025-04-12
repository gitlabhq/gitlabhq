import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlForm } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PackagesProtectionRuleForm from '~/packages_and_registries/settings/project/components/packages_protection_rule_form.vue';
import createPackagesProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/create_packages_protection_rule.mutation.graphql';
import updatePackagesProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_packages_protection_rule.mutation.graphql';
import {
  packagesProtectionRulesData,
  createPackagesProtectionRuleMutationPayload,
  createPackagesProtectionRuleMutationInput,
  createPackagesProtectionRuleMutationPayloadErrors,
  updatePackagesProtectionRuleMutationPayload,
} from '../mock_data';

Vue.use(VueApollo);

describe('Packages Protection Rule Form', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
    glFeatures: {
      packagesProtectedPackagesDelete: true,
    },
  };

  const findPackageNamePatternInput = () =>
    wrapper.findByRole('textbox', { name: /name pattern/i });
  const findPackageTypeSelect = () => wrapper.findByRole('combobox', { name: /type/i });
  const findMinimumAccessLevelForPushSelect = () =>
    wrapper.findByRole('combobox', { name: /minimum access level for push/i });
  const findMinimumAccessLevelForDeleteSelect = () =>
    wrapper.findByRole('combobox', { name: /minimum access level for delete/i });
  const findCancelButton = () => wrapper.findByRole('button', { name: /cancel/i });
  const findSubmitButton = () => wrapper.findByTestId('submit-btn');
  const findForm = () => wrapper.findComponent(GlForm);

  const setSelectValue = async (selectWrapper, value) => {
    await selectWrapper.setValue(value);
    // Work around compat flag which prevents change event from being triggered by setValue.
    // TODO: Disable WRAPPER_SET_VALUE_DOES_NOT_TRIGGER_CHANGE globally:
    // https://gitlab.com/gitlab-org/gitlab/-/issues/526008
    await selectWrapper.trigger('change');
  };

  const mountComponent = ({ data, config, props, provide = defaultProvidedValues } = {}) => {
    wrapper = mountExtended(PackagesProtectionRuleForm, {
      provide,
      propsData: props,
      data() {
        return { ...data };
      },
      ...config,
    });
  };

  const mountComponentWithApollo = ({
    props = {},
    provide = defaultProvidedValues,
    mutationResolver,
    updatePackagesProtectionRuleMutationResolver = jest
      .fn()
      .mockResolvedValue(updatePackagesProtectionRuleMutationPayload()),
  } = {}) => {
    const requestHandlers = [
      [createPackagesProtectionRuleMutation, mutationResolver],
      [updatePackagesProtectionRuleMutation, updatePackagesProtectionRuleMutationResolver],
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
    describe('form field "packageType"', () => {
      const packageTypeSelectOptions = () =>
        findPackageTypeSelect()
          .findAll('option')
          .wrappers.map((option) => option.element.value);

      it('contains available options', () => {
        mountComponent();

        expect(findPackageTypeSelect().exists()).toBe(true);
        expect(packageTypeSelectOptions()).toEqual(['CONAN', 'MAVEN', 'NPM', 'PYPI']);
      });
    });

    describe('form field "minimumAccessLevelForPushSelect"', () => {
      const findMinimumAccessLevelForPushSelectOptionValues = () =>
        findMinimumAccessLevelForPushSelect()
          .findAll('option')
          .wrappers.map((option) => option.element.value);

      it('contains only the options for maintainer and owner', () => {
        mountComponent();

        expect(findMinimumAccessLevelForPushSelect().exists()).toBe(true);
        expect(findMinimumAccessLevelForPushSelectOptionValues()).toEqual([
          '',
          'MAINTAINER',
          'OWNER',
          'ADMIN',
        ]);
      });

      it('sets correct option for "null" value', () => {
        mountComponent({
          props: {
            rule: { ...packagesProtectionRulesData[0], minimumAccessLevelForPush: null },
          },
        });

        expect(findMinimumAccessLevelForPushSelect().element.value).toBe('');
      });

      describe('when feature flag packagesProtectedPackagesDelete is disabled', () => {
        it('does not show option "Developer (default)"', () => {
          mountComponent({
            provide: {
              ...defaultProvidedValues,
              glFeatures: {
                ...defaultProvidedValues.glFeatures,
                packagesProtectedPackagesDelete: false,
              },
            },
          });

          expect(findMinimumAccessLevelForPushSelect().exists()).toBe(true);
          expect(findMinimumAccessLevelForPushSelectOptionValues()).toEqual([
            'MAINTAINER',
            'OWNER',
            'ADMIN',
          ]);
        });
      });
    });

    describe('form field "minimumAccessLevelForDeleteSelect"', () => {
      const findMinimumAccessLevelForDeleteSelectOptionValues = () =>
        findMinimumAccessLevelForDeleteSelect()
          .findAll('option')
          .wrappers.map((option) => option.element.value);

      it('contains only the options for maintainer and owner', () => {
        mountComponent();

        expect(findMinimumAccessLevelForDeleteSelect().exists()).toBe(true);
        expect(findMinimumAccessLevelForDeleteSelectOptionValues()).toEqual(['', 'OWNER', 'ADMIN']);
      });

      describe('when form has prop "rule"', () => {
        it('sets correct option for "null" value', () => {
          mountComponent({
            props: {
              rule: { ...packagesProtectionRulesData[0], minimumAccessLevelForDelete: null },
            },
          });

          expect(findMinimumAccessLevelForDeleteSelect().element.value).toBe('');
        });
      });

      describe('when feature flag packagesProtectedPackagesDelete is disabled', () => {
        it('does not show form field "minimumAccessLevelForDeleteSelect"', () => {
          mountComponent({
            provide: {
              ...defaultProvidedValues,
              glFeatures: {
                ...defaultProvidedValues.glFeatures,
                packagesProtectedPackagesDelete: false,
              },
            },
          });
          expect(findMinimumAccessLevelForDeleteSelect().exists()).toBe(false);
        });
      });
    });

    describe('when graphql mutation is in progress', () => {
      beforeEach(() => {
        mountComponentWithApollo();

        findForm().trigger('submit');
      });

      it('disables all form fields', () => {
        expect(findSubmitButton().props('disabled')).toBe(true);
        expect(findPackageNamePatternInput().attributes('disabled')).toBe('disabled');
        expect(findPackageTypeSelect().attributes('disabled')).toBe('disabled');
        expect(findMinimumAccessLevelForPushSelect().attributes('disabled')).toBe('disabled');
        expect(findMinimumAccessLevelForDeleteSelect().attributes('disabled')).toBe('disabled');
      });

      it('displays a loading spinner', () => {
        expect(findSubmitButton().props('loading')).toBe(true);
      });
    });
  });

  describe.each`
    description                       | props                                       | submitButtonText
    ${'when form has no prop "rule"'} | ${{}}                                       | ${'Add rule'}
    ${'when form has prop "rule"'}    | ${{ rule: packagesProtectionRulesData[0] }} | ${'Save changes'}
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

  describe('form actions', () => {
    describe('submit button', () => {
      it.each`
        packageNamePattern                                              | submitButtonDisabled
        ${''}                                                           | ${true}
        ${' '}                                                          | ${true}
        ${createPackagesProtectionRuleMutationInput.packageNamePattern} | ${false}
      `(
        'when packageNamePattern is "$packageNamePattern" then the disabled state of the submit button is $submitButtonDisabled',
        async ({ packageNamePattern, submitButtonDisabled }) => {
          mountComponent();

          expect(findSubmitButton().props('disabled')).toBe(true);

          await findPackageNamePatternInput().setValue(packageNamePattern);

          expect(findSubmitButton().props('disabled')).toBe(submitButtonDisabled);
        },
      );
    });
  });

  describe('form events', () => {
    describe('reset', () => {
      const mutationResolver = jest
        .fn()
        .mockResolvedValue(createPackagesProtectionRuleMutationPayload());

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

    describe('submit a new rule', () => {
      const findAlert = () => wrapper.findByRole('alert');

      const submitForm = () => {
        findForm().trigger('submit');
        return waitForPromises();
      };

      it('dispatches correct apollo mutation', async () => {
        const mutationResolver = jest
          .fn()
          .mockResolvedValue(createPackagesProtectionRuleMutationPayload());
        const updatePackagesProtectionRuleMutationResolver = jest
          .fn()
          .mockResolvedValue(updatePackagesProtectionRuleMutationPayload());

        mountComponentWithApollo({
          mutationResolver,
          updatePackagesProtectionRuleMutationResolver,
        });

        await findPackageNamePatternInput().setValue(
          createPackagesProtectionRuleMutationInput.packageNamePattern,
        );

        await submitForm();

        expect(mutationResolver).toHaveBeenCalledWith({
          input: {
            projectPath: 'path',
            ...createPackagesProtectionRuleMutationInput,
            minimumAccessLevelForDelete: 'OWNER',
          },
        });
        expect(updatePackagesProtectionRuleMutationResolver).not.toHaveBeenCalled();
      });

      it('dispatches correct apollo mutation when no minimumAccessLevelForPush is selected', async () => {
        const mutationResolver = jest
          .fn()
          .mockResolvedValue(createPackagesProtectionRuleMutationPayload());

        mountComponentWithApollo({ mutationResolver });

        await findPackageNamePatternInput().setValue(
          createPackagesProtectionRuleMutationInput.packageNamePattern,
        );
        await setSelectValue(findMinimumAccessLevelForPushSelect(), '');
        await setSelectValue(findMinimumAccessLevelForDeleteSelect(), 'ADMIN');

        await submitForm();

        expect(mutationResolver).toHaveBeenCalledWith({
          input: {
            projectPath: 'path',
            ...createPackagesProtectionRuleMutationInput,
            minimumAccessLevelForPush: null,
            minimumAccessLevelForDelete: 'ADMIN',
          },
        });
      });

      it('emits event "submit" when apollo mutation successful', async () => {
        const mutationResolver = jest
          .fn()
          .mockResolvedValue(createPackagesProtectionRuleMutationPayload());

        mountComponentWithApollo({ mutationResolver });

        await submitForm();

        expect(wrapper.emitted('submit')).toBeDefined();
        const expectedEventSubmitPayload =
          createPackagesProtectionRuleMutationPayload().data.createPackagesProtectionRule
            .packageProtectionRule;
        expect(wrapper.emitted('submit')[0]).toEqual([expectedEventSubmitPayload]);

        expect(wrapper.emitted()).not.toHaveProperty('cancel');
      });

      it('shows error alert with general message when apollo mutation request responds with errors', async () => {
        mountComponentWithApollo({
          mutationResolver: jest.fn().mockResolvedValue(
            createPackagesProtectionRuleMutationPayload({
              errors: createPackagesProtectionRuleMutationPayloadErrors,
            }),
          ),
        });

        await submitForm();

        expect(findAlert().isVisible()).toBe(true);
        expect(findAlert().text()).toBe(createPackagesProtectionRuleMutationPayloadErrors[0]);
      });

      it('shows error alert with general message when apollo mutation request fails', async () => {
        mountComponentWithApollo({
          mutationResolver: jest.fn().mockRejectedValue(new Error('GraphQL error')),
        });

        await submitForm();

        expect(findAlert().isVisible()).toBe(true);
        expect(findAlert().text()).toMatch(
          'Something went wrong while saving the package protection rule',
        );
      });
    });

    describe('update existing rule', () => {
      const findAlert = () => wrapper.findByRole('alert');

      const submitForm = async () => {
        await findPackageNamePatternInput().setValue(
          createPackagesProtectionRuleMutationInput.packageNamePattern,
        );
        await findMinimumAccessLevelForPushSelect().findAll('option').at(0).setSelected();
        await findMinimumAccessLevelForDeleteSelect().findAll('option').at(2).setSelected();

        findForm().trigger('submit');

        await waitForPromises();
      };

      const [rule] = packagesProtectionRulesData;

      it('dispatches correct apollo mutation', async () => {
        const mutationResolver = jest
          .fn()
          .mockResolvedValue(createPackagesProtectionRuleMutationPayload());
        const updatePackagesProtectionRuleMutationResolver = jest
          .fn()
          .mockResolvedValue(updatePackagesProtectionRuleMutationPayload());

        mountComponentWithApollo({
          props: { rule },
          mutationResolver,
          updatePackagesProtectionRuleMutationResolver,
        });

        await submitForm();

        expect(mutationResolver).not.toHaveBeenCalled();
        expect(updatePackagesProtectionRuleMutationResolver).toHaveBeenCalledWith({
          input: {
            id: packagesProtectionRulesData[0].id,
            ...createPackagesProtectionRuleMutationInput,
            minimumAccessLevelForDelete: 'ADMIN',
            minimumAccessLevelForPush: null,
          },
        });
      });

      it('emits event "submit" when apollo mutation successful', async () => {
        const mutationResolver = jest
          .fn()
          .mockResolvedValue(createPackagesProtectionRuleMutationPayload());

        mountComponentWithApollo({
          props: { rule },
          mutationResolver,
        });

        await submitForm();

        expect(wrapper.emitted('submit')).toBeDefined();
        const expectedEventSubmitPayload =
          updatePackagesProtectionRuleMutationPayload().data.updatePackagesProtectionRule
            .packageProtectionRule;
        expect(wrapper.emitted('submit')[0]).toEqual([expectedEventSubmitPayload]);

        expect(wrapper.emitted()).not.toHaveProperty('cancel');
      });

      it('shows error alert with general message when apollo mutation request responds with errors', async () => {
        mountComponentWithApollo({
          props: { rule },
          updatePackagesProtectionRuleMutationResolver: jest.fn().mockResolvedValue(
            updatePackagesProtectionRuleMutationPayload({
              errors: createPackagesProtectionRuleMutationPayloadErrors,
            }),
          ),
        });

        await submitForm();

        expect(findAlert().isVisible()).toBe(true);
        expect(findAlert().text()).toBe(createPackagesProtectionRuleMutationPayloadErrors[0]);
      });

      it('shows error alert with general message when apollo mutation request fails', async () => {
        mountComponentWithApollo({
          props: { rule },
          updatePackagesProtectionRuleMutationResolver: jest
            .fn()
            .mockRejectedValue(new Error('GraphQL error')),
        });

        await submitForm();

        expect(findAlert().isVisible()).toBe(true);
        expect(findAlert().text()).toMatch(
          'Something went wrong while saving the package protection rule',
        );
      });
    });
  });
});

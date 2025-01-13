import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlForm } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PackagesProtectionRuleForm from '~/packages_and_registries/settings/project/components/packages_protection_rule_form.vue';
import createPackagesProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/create_packages_protection_rule.mutation.graphql';
import {
  createPackagesProtectionRuleMutationPayload,
  createPackagesProtectionRuleMutationInput,
  createPackagesProtectionRuleMutationPayloadErrors,
} from '../mock_data';

Vue.use(VueApollo);

describe('Packages Protection Rule Form', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
    glFeatures: {
      packagesProtectedPackagesConan: true,
    },
  };

  const findPackageNamePatternInput = () =>
    wrapper.findByRole('textbox', { name: /name pattern/i });
  const findPackageTypeSelect = () => wrapper.findByRole('combobox', { name: /type/i });
  const findMinimumAccessLevelForPushSelect = () =>
    wrapper.findByRole('combobox', { name: /minimum access level for push/i });
  const findSubmitButton = () => wrapper.findByTestId('add-rule-btn');
  const findForm = () => wrapper.findComponent(GlForm);

  const mountComponent = ({ data, config, provide = defaultProvidedValues } = {}) => {
    wrapper = mountExtended(PackagesProtectionRuleForm, {
      provide,
      data() {
        return { ...data };
      },
      ...config,
    });
  };

  const mountComponentWithApollo = ({ provide = defaultProvidedValues, mutationResolver } = {}) => {
    const requestHandlers = [[createPackagesProtectionRuleMutation, mutationResolver]];

    fakeApollo = createMockApollo(requestHandlers);

    mountComponent({
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
        expect(packageTypeSelectOptions()).toEqual(['CONAN', 'NPM', 'PYPI']);
      });

      describe('when feature flag packagesProtectedPackagesConan is disabled', () => {
        it('contains available options without option "CONAN"', () => {
          mountComponent({
            provide: {
              ...defaultProvidedValues,
              glFeatures: {
                ...defaultProvidedValues.glFeatures,
                packagesProtectedPackagesConan: false,
              },
            },
          });

          expect(findPackageTypeSelect().exists()).toBe(true);
          expect(packageTypeSelectOptions()).toEqual(['NPM', 'PYPI']);
        });
      });
    });

    describe('form field "minimumAccessLevelForPushSelect"', () => {
      it('contains only the options for maintainer and owner', () => {
        mountComponent();

        expect(findMinimumAccessLevelForPushSelect().exists()).toBe(true);
        const minimumAccessLevelForPushSelectOptions = findMinimumAccessLevelForPushSelect()
          .findAll('option')
          .wrappers.map((option) => option.element.value);
        expect(minimumAccessLevelForPushSelectOptions).toEqual(['MAINTAINER', 'OWNER', 'ADMIN']);
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
      });

      it('displays a loading spinner', () => {
        expect(findSubmitButton().props('loading')).toBe(true);
      });
    });
  });

  describe('form actions', () => {
    describe('button "Protect"', () => {
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

    describe('submit', () => {
      const findAlert = () => wrapper.findByRole('alert');

      const submitForm = () => {
        findForm().trigger('submit');
        return waitForPromises();
      };

      it('dispatches correct apollo mutation', async () => {
        const mutationResolver = jest
          .fn()
          .mockResolvedValue(createPackagesProtectionRuleMutationPayload());

        mountComponentWithApollo({ mutationResolver });

        await findPackageNamePatternInput().setValue(
          createPackagesProtectionRuleMutationInput.packageNamePattern,
        );

        await submitForm();

        expect(mutationResolver).toHaveBeenCalledWith({
          input: { projectPath: 'path', ...createPackagesProtectionRuleMutationInput },
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
  });
});

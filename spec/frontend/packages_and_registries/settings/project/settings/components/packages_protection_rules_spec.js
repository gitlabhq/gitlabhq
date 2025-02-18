import { GlLoadingIcon, GlKeysetPagination, GlModal, GlTable } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getBinding } from 'helpers/vue_mock_directive';
import PackagesProtectionRules from '~/packages_and_registries/settings/project/components/packages_protection_rules.vue';
import PackagesProtectionRuleForm from '~/packages_and_registries/settings/project/components/packages_protection_rule_form.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import packagesProtectionRuleQuery from '~/packages_and_registries/settings/project/graphql/queries/get_packages_protection_rules.query.graphql';
import deletePackagesProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/delete_packages_protection_rule.mutation.graphql';
import updatePackagesProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_packages_protection_rule.mutation.graphql';
import {
  packagesProtectionRuleQueryPayload,
  packagesProtectionRulesData,
  deletePackagesProtectionRuleMutationPayload,
  updatePackagesProtectionRuleMutationPayload,
} from '../mock_data';

Vue.use(VueApollo);

describe('Packages protection rules project settings', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
  };

  const $toast = { show: jest.fn() };

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findEmptyText = () => wrapper.findByText('No packages are protected.');
  const findTable = () =>
    extendedWrapper(wrapper.findByRole('table', { name: /protected packages/i }));
  const findTableBody = () => extendedWrapper(findTable().findAllByRole('rowgroup').at(1));
  const findTableRow = (i) => extendedWrapper(findTableBody().findAllByRole('row').at(i));
  const findTableRowButtonDelete = (i) =>
    extendedWrapper(wrapper.findAllByTestId('delete-rule-btn').at(i));
  const findTableLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findProtectionRuleForm = () => wrapper.findComponent(PackagesProtectionRuleForm);
  const findAddProtectionRuleButton = () =>
    wrapper.findByRole('button', { name: /add protection rule/i });
  const findAlert = () => wrapper.findByRole('alert');
  const findModal = () => wrapper.findComponent(GlModal);

  const mountComponent = (mountFn = mountExtended, provide = defaultProvidedValues, config) => {
    wrapper = mountFn(PackagesProtectionRules, {
      stubs: {
        GlModal: true,
      },
      mocks: {
        $toast,
      },
      provide,
      ...config,
    });
  };

  const createComponent = ({
    mountFn = mountExtended,
    provide = defaultProvidedValues,
    packagesProtectionRuleQueryResolver = jest
      .fn()
      .mockResolvedValue(packagesProtectionRuleQueryPayload()),
    deletePackagesProtectionRuleMutationResolver = jest
      .fn()
      .mockResolvedValue(deletePackagesProtectionRuleMutationPayload()),
    updatePackagesProtectionRuleMutationResolver = jest
      .fn()
      .mockResolvedValue(updatePackagesProtectionRuleMutationPayload()),
    config = {},
  } = {}) => {
    const requestHandlers = [
      [packagesProtectionRuleQuery, packagesProtectionRuleQueryResolver],
      [deletePackagesProtectionRuleMutation, deletePackagesProtectionRuleMutationResolver],
      [updatePackagesProtectionRuleMutation, updatePackagesProtectionRuleMutationResolver],
    ];

    fakeApollo = createMockApollo(requestHandlers);

    mountComponent(mountFn, provide, {
      apolloProvider: fakeApollo,
      ...config,
    });
  };

  it('renders the crud component with table', async () => {
    createComponent();

    await waitForPromises();

    expect(findCrudComponent().props()).toMatchObject({
      title: 'Protected packages',
      toggleText: 'Add protection rule',
    });
    expect(findTable().exists()).toBe(true);
  });

  it('hides table when no protection rules exist', async () => {
    createComponent({
      packagesProtectionRuleQueryResolver: jest.fn().mockResolvedValue(
        packagesProtectionRuleQueryPayload({
          nodes: [],
          pageInfo: {
            hasNextPage: false,
            hasPreviousPage: false,
            startCursor: null,
            endCursor: null,
          },
        }),
      ),
    });
    await waitForPromises();

    expect(wrapper.findComponent(GlTable).exists()).toBe(false);
    expect(findEmptyText().exists()).toBe(true);
  });

  describe('table "package protection rules"', () => {
    it('renders table with packages protection rules', async () => {
      createComponent();

      await waitForPromises();

      expect(findTable().exists()).toBe(true);

      packagesProtectionRuleQueryPayload().data.project.packagesProtectionRules.nodes.forEach(
        (protectionRule, i) => {
          expect(findTableRow(i).text()).toContain(protectionRule.packageNamePattern);
          expect(findTableRow(i).text()).toContain('npm');
          expect(findTableRow(i).text()).toContain('Maintainer');
        },
      );
    });

    it('shows loading icon', () => {
      createComponent();

      expect(findTableLoadingIcon().exists()).toBe(true);
      expect(findTableLoadingIcon().attributes('aria-label')).toBe('Loading');
    });

    it('calls graphql api query', () => {
      const packagesProtectionRuleQueryResolver = jest
        .fn()
        .mockResolvedValue(packagesProtectionRuleQueryPayload());
      createComponent({ packagesProtectionRuleQueryResolver });

      expect(packagesProtectionRuleQueryResolver).toHaveBeenCalledWith(
        expect.objectContaining({ projectPath: defaultProvidedValues.projectPath }),
      );
    });

    describe('table pagination', () => {
      const findPagination = () => wrapper.findComponent(GlKeysetPagination);

      it('renders pagination', async () => {
        createComponent();

        await waitForPromises();

        expect(findPagination().exists()).toBe(true);
        expect(findPagination().props()).toMatchObject({
          endCursor: '10',
          startCursor: '0',
          hasNextPage: true,
          hasPreviousPage: false,
        });
      });

      it('calls initial graphql api query with pagination information', () => {
        const packagesProtectionRuleQueryResolver = jest
          .fn()
          .mockResolvedValue(packagesProtectionRuleQueryPayload());
        createComponent({ packagesProtectionRuleQueryResolver });

        expect(packagesProtectionRuleQueryResolver).toHaveBeenCalledWith(
          expect.objectContaining({
            projectPath: defaultProvidedValues.projectPath,
            first: 10,
          }),
        );
      });

      it('show alert when GraphQL request fails', async () => {
        const protectionRuleQueryResolverRejectedErrorMessage = 'Error protectionRuleQueryResolver';
        const packagesProtectionRuleQueryResolver = jest
          .fn()
          .mockRejectedValue(new Error(protectionRuleQueryResolverRejectedErrorMessage));

        createComponent({ packagesProtectionRuleQueryResolver });

        await waitForPromises();

        expect(findAlert().isVisible()).toBe(true);
        expect(findAlert().text()).toBe(protectionRuleQueryResolverRejectedErrorMessage);
      });

      describe('when button "Previous" is clicked', () => {
        const packagesProtectionRuleQueryResolver = jest
          .fn()
          .mockResolvedValueOnce(
            packagesProtectionRuleQueryPayload({
              nodes: packagesProtectionRulesData.slice(10),
              pageInfo: {
                hasNextPage: false,
                hasPreviousPage: true,
                startCursor: '10',
                endCursor: '16',
              },
            }),
          )
          .mockResolvedValueOnce(packagesProtectionRuleQueryPayload());

        const findPaginationButtonPrev = () =>
          extendedWrapper(findPagination()).findByRole('button', { name: /previous/i });

        beforeEach(async () => {
          createComponent({ packagesProtectionRuleQueryResolver });

          await waitForPromises();

          findPaginationButtonPrev().trigger('click');
        });

        it('sends a second graphql api query with new pagination params', () => {
          expect(packagesProtectionRuleQueryResolver).toHaveBeenCalledTimes(2);
          expect(packagesProtectionRuleQueryResolver).toHaveBeenLastCalledWith(
            expect.objectContaining({
              before: '10',
              last: 10,
              projectPath: 'path',
            }),
          );
        });
      });

      describe('when button "Next" is clicked', () => {
        const packagesProtectionRuleQueryResolver = jest
          .fn()
          .mockResolvedValue(packagesProtectionRuleQueryPayload())
          .mockResolvedValueOnce(packagesProtectionRuleQueryPayload())
          .mockResolvedValueOnce(
            packagesProtectionRuleQueryPayload({
              nodes: packagesProtectionRulesData.slice(10),
              pageInfo: {
                hasNextPage: true,
                hasPreviousPage: false,
                startCursor: '1',
                endCursor: '10',
              },
            }),
          );

        const findPaginationButtonNext = () =>
          extendedWrapper(findPagination()).findByRole('button', { name: /next/i });

        beforeEach(async () => {
          createComponent({ packagesProtectionRuleQueryResolver });

          await waitForPromises();

          findPaginationButtonNext().trigger('click');
        });

        it('sends a second graphql api query with new pagination params', () => {
          expect(packagesProtectionRuleQueryResolver).toHaveBeenCalledTimes(2);
          expect(packagesProtectionRuleQueryResolver).toHaveBeenLastCalledWith(
            expect.objectContaining({
              after: '10',
              first: 10,
              projectPath: 'path',
            }),
          );
        });

        it('displays table in busy state and shows loading icon inside table', async () => {
          expect(findTable().exists()).toBe(true);
          expect(findTable().attributes('aria-busy')).toBe('true');

          await waitForPromises();

          expect(findTableLoadingIcon().exists()).toBe(false);
          expect(findTable().attributes('aria-busy')).toBe('false');
        });
      });
    });

    describe('column "Minimum access level for push" with selectbox (combobox)', () => {
      const findComboboxInTableRow = (i) =>
        extendedWrapper(wrapper.findAllByTestId('push-access-select').at(i));

      it('contains combobox with respective access level', async () => {
        createComponent();

        await waitForPromises();

        expect(findComboboxInTableRow(0).isVisible()).toBe(true);
        expect(findComboboxInTableRow(0).attributes('disabled')).toBeUndefined();
        expect(findComboboxInTableRow(0).element.value).toBe(
          packagesProtectionRulesData[0].minimumAccessLevelForPush,
        );
      });

      it('contains combobox with allowed access levels', async () => {
        createComponent();

        await waitForPromises();

        ['Maintainer', 'Owner', 'Administrator'].forEach((optionName) => {
          const selectOption = findComboboxInTableRow(0).findByRole('option', {
            name: optionName,
          });
          expect(selectOption.exists()).toBe(true);
        });
      });

      describe('when value changes', () => {
        const accessLevelValueOwner = 'OWNER';
        const accessLevelValueMaintainer = 'MAINTAINER';
        const accessLevelValueAdmin = 'ADMIN';

        it('only changes the value of the selectbox in the same row', async () => {
          createComponent();

          await waitForPromises();

          expect(findComboboxInTableRow(0).props('value')).toBe(accessLevelValueMaintainer);
          await findComboboxInTableRow(0).findAll('option').at(1).setSelected();
          expect(findComboboxInTableRow(0).props('value')).toBe(accessLevelValueOwner);

          expect(findComboboxInTableRow(1).props('value')).toBe(accessLevelValueMaintainer);
          await findComboboxInTableRow(1).findAll('option').at(2).setSelected();
          expect(findComboboxInTableRow(1).props('value')).toBe(accessLevelValueAdmin);

          expect(findComboboxInTableRow(0).props('value')).toBe(accessLevelValueOwner);
        });

        it('sends graphql mutation', async () => {
          const updatePackagesProtectionRuleMutationResolver = jest
            .fn()
            .mockResolvedValue(updatePackagesProtectionRuleMutationPayload());

          createComponent({ updatePackagesProtectionRuleMutationResolver });

          await waitForPromises();

          await findComboboxInTableRow(0).findAll('option').at(1).setSelected();

          expect(updatePackagesProtectionRuleMutationResolver).toHaveBeenCalledTimes(1);
          expect(updatePackagesProtectionRuleMutationResolver).toHaveBeenCalledWith({
            input: {
              id: packagesProtectionRulesData[0].id,
              minimumAccessLevelForPush: accessLevelValueOwner,
            },
          });
        });

        it('disables only the changed selectbox and keeps other selectboxes in other table rows active when graphql mutation is in progress', async () => {
          createComponent();

          await waitForPromises();

          await findComboboxInTableRow(0).findAll('option').at(1).setSelected();

          expect(findComboboxInTableRow(0).props('disabled')).toBe(true);
          expect(findComboboxInTableRow(1).props('disabled')).toBe(false);

          await waitForPromises();

          expect(findComboboxInTableRow(0).props('disabled')).toBe(false);
          expect(findComboboxInTableRow(1).props('disabled')).toBe(false);
        });

        it('disables selectbox (and other interactive elements in table row) when graphql mutation is in progress', async () => {
          createComponent();

          await waitForPromises();

          await findComboboxInTableRow(0).findAll('option').at(1).setSelected();

          expect(findComboboxInTableRow(0).props('disabled')).toBe(true);
          expect(findTableRowButtonDelete(0).props('disabled')).toBe(true);

          await waitForPromises();

          expect(findComboboxInTableRow(1).props('disabled')).toBe(false);
          expect(findTableRowButtonDelete(1).props('disabled')).toBe(false);
        });

        it('handles erroneous graphql mutation', async () => {
          const updatePackagesProtectionRuleMutationResolver = jest
            .fn()
            .mockRejectedValue(new Error('error'));

          createComponent({ updatePackagesProtectionRuleMutationResolver });

          await waitForPromises();

          await findComboboxInTableRow(0).findAll('option').at(1).setSelected();

          await waitForPromises();

          expect(findAlert().isVisible()).toBe(true);
          expect(findAlert().text()).toBe('error');
        });

        it('handles graphql mutation with error response', async () => {
          const serverErrorMessage = 'Server error message';
          const updatePackagesProtectionRuleMutationResolver = jest.fn().mockResolvedValue(
            updatePackagesProtectionRuleMutationPayload({
              packageProtectionRule: null,
              errors: [serverErrorMessage],
            }),
          );

          createComponent({ updatePackagesProtectionRuleMutationResolver });

          await waitForPromises();

          await findComboboxInTableRow(0).findAll('option').at(1).setSelected();

          await waitForPromises();

          expect(findAlert().isVisible()).toBe(true);
          expect(findAlert().text()).toBe(serverErrorMessage);
        });

        it('shows a toast with success message', async () => {
          createComponent();

          await waitForPromises();

          await findComboboxInTableRow(0).findAll('option').at(1).setSelected();

          await waitForPromises();

          expect($toast.show).toHaveBeenCalledWith('Package protection rule updated.');
        });
      });
    });

    describe('column "Actions"', () => {
      describe('button "Delete"', () => {
        it('exists in table', async () => {
          createComponent();

          await waitForPromises();

          expect(findTableRowButtonDelete(0).exists()).toBe(true);
        });

        describe('when button is clicked', () => {
          it('renders the "delete container protection rule" confirmation modal', async () => {
            createComponent();

            await waitForPromises();

            await findTableRowButtonDelete(0).trigger('click');

            const modalId = getBinding(findTableRowButtonDelete(0).element, 'gl-modal');

            expect(findModal().props('modal-id')).toBe(modalId);
            expect(findModal().props('title')).toBe('Delete package protection rule?');
            expect(findModal().text()).toContain(
              'Users with at least the Developer role for this project will be able to publish, edit, and delete packages with this package name.',
            );
          });
        });
      });
    });
  });

  describe('modal "confirmation for delete action"', () => {
    const createComponentAndClickButtonDeleteInTableRow = async ({
      tableRowIndex = 0,
      deletePackagesProtectionRuleMutationResolver = jest
        .fn()
        .mockResolvedValue(deletePackagesProtectionRuleMutationPayload()),
    } = {}) => {
      createComponent({ deletePackagesProtectionRuleMutationResolver });

      await waitForPromises();

      findTableRowButtonDelete(tableRowIndex).trigger('click');
    };

    describe('when modal button "primary" clicked', () => {
      const clickOnModalPrimaryBtn = () => findModal().vm.$emit('primary');

      it('disables the button when graphql mutation is executed', async () => {
        await createComponentAndClickButtonDeleteInTableRow();

        await clickOnModalPrimaryBtn();

        expect(findTableRowButtonDelete(0).props().disabled).toBe(true);

        expect(findTableRowButtonDelete(1).props().disabled).toBe(false);
      });

      it('sends graphql mutation', async () => {
        const deletePackagesProtectionRuleMutationResolver = jest
          .fn()
          .mockResolvedValue(deletePackagesProtectionRuleMutationPayload());

        await createComponentAndClickButtonDeleteInTableRow({
          deletePackagesProtectionRuleMutationResolver,
        });

        await clickOnModalPrimaryBtn();

        expect(deletePackagesProtectionRuleMutationResolver).toHaveBeenCalledTimes(1);
        expect(deletePackagesProtectionRuleMutationResolver).toHaveBeenCalledWith({
          input: { id: packagesProtectionRulesData[0].id },
        });
      });

      it('handles erroneous graphql mutation', async () => {
        const alertErrorMessage = 'Client error message';
        const deletePackagesProtectionRuleMutationResolver = jest
          .fn()
          .mockRejectedValue(new Error(alertErrorMessage));

        await createComponentAndClickButtonDeleteInTableRow({
          deletePackagesProtectionRuleMutationResolver,
        });

        await clickOnModalPrimaryBtn();

        await waitForPromises();

        expect(findAlert().isVisible()).toBe(true);
        expect(findAlert().text()).toBe(alertErrorMessage);
      });

      it('handles graphql mutation with error response', async () => {
        const alertErrorMessage = 'Server error message';
        const deletePackagesProtectionRuleMutationResolver = jest.fn().mockResolvedValue({
          data: {
            deletePackagesProtectionRule: {
              packageProtectionRule: null,
              errors: [alertErrorMessage],
            },
          },
        });

        await createComponentAndClickButtonDeleteInTableRow({
          deletePackagesProtectionRuleMutationResolver,
        });

        await clickOnModalPrimaryBtn();

        await waitForPromises();

        expect(findAlert().isVisible()).toBe(true);
        expect(findAlert().text()).toBe(alertErrorMessage);
      });

      it('refetches package protection rules after successful graphql mutation', async () => {
        const deletePackagesProtectionRuleMutationResolver = jest
          .fn()
          .mockResolvedValue(deletePackagesProtectionRuleMutationPayload());

        const packagesProtectionRuleQueryResolver = jest
          .fn()
          .mockResolvedValue(packagesProtectionRuleQueryPayload());

        createComponent({
          packagesProtectionRuleQueryResolver,
          deletePackagesProtectionRuleMutationResolver,
        });

        await waitForPromises();

        expect(packagesProtectionRuleQueryResolver).toHaveBeenCalledTimes(1);

        await findTableRowButtonDelete(0).trigger('click');

        await clickOnModalPrimaryBtn();

        await waitForPromises();

        expect(packagesProtectionRuleQueryResolver).toHaveBeenCalledTimes(2);
      });

      it('shows a toast with success message', async () => {
        await createComponentAndClickButtonDeleteInTableRow();

        await clickOnModalPrimaryBtn();

        await waitForPromises();

        expect($toast.show).toHaveBeenCalledWith('Package protection rule deleted.');
      });
    });
  });

  describe('button "Add protection rule"', () => {
    it('button exists', async () => {
      createComponent();

      await waitForPromises();

      expect(findAddProtectionRuleButton().isVisible()).toBe(true);
    });

    it('does not initially render form "add package protection"', async () => {
      createComponent();

      await waitForPromises();

      expect(findAddProtectionRuleButton().isVisible()).toBe(true);
      expect(findProtectionRuleForm().exists()).toBe(false);
    });

    describe('when button is clicked', () => {
      beforeEach(async () => {
        createComponent();

        await waitForPromises();

        await findAddProtectionRuleButton().trigger('click');
      });

      it('renders form "add package protection"', () => {
        expect(findProtectionRuleForm().exists()).toBe(true);
      });

      it('hides the button "add protection rule"', () => {
        expect(findAddProtectionRuleButton().exists()).toBe(false);
      });
    });
  });

  describe('form "add protection rule"', () => {
    let packagesProtectionRuleQueryResolver;

    beforeEach(async () => {
      packagesProtectionRuleQueryResolver = jest
        .fn()
        .mockResolvedValue(packagesProtectionRuleQueryPayload());

      createComponent({ packagesProtectionRuleQueryResolver });

      await waitForPromises();

      await findAddProtectionRuleButton().trigger('click');
    });

    it('handles event "submit"', async () => {
      await findProtectionRuleForm().vm.$emit('submit');

      expect(packagesProtectionRuleQueryResolver).toHaveBeenCalledTimes(2);

      expect(findProtectionRuleForm().exists()).toBe(false);
      expect(findAddProtectionRuleButton().attributes('disabled')).not.toBeDefined();
    });

    it('handles event "cancel"', async () => {
      await findProtectionRuleForm().vm.$emit('cancel');

      expect(packagesProtectionRuleQueryResolver).toHaveBeenCalledTimes(1);

      expect(findProtectionRuleForm().exists()).toBe(false);
      expect(findAddProtectionRuleButton().attributes()).not.toHaveProperty('disabled');
    });
  });

  describe('alert "errorMessage"', () => {
    const findAlertButtonDismiss = () => wrapper.findByRole('button', { name: /dismiss/i });

    it('renders alert and dismisses it correctly', async () => {
      const alertErrorMessage = 'Error message';
      createComponent({
        config: {
          data() {
            return {
              alertErrorMessage,
            };
          },
        },
      });

      await waitForPromises();

      expect(findAlert().isVisible()).toBe(true);
      expect(findAlert().text()).toBe(alertErrorMessage);

      await findAlertButtonDismiss().trigger('click');

      expect(findAlert().exists()).toBe(false);
    });
  });
});

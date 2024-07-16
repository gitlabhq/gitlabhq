import { GlLoadingIcon, GlKeysetPagination, GlModal } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { getBinding } from 'helpers/vue_mock_directive';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ContainerProtectionRuleForm from '~/packages_and_registries/settings/project/components/container_protection_rule_form.vue';
import ContainerProtectionRules from '~/packages_and_registries/settings/project/components/container_protection_rules.vue';
import SettingsBlock from '~/packages_and_registries/shared/components/settings_block.vue';
import ContainerProtectionRuleQuery from '~/packages_and_registries/settings/project/graphql/queries/get_container_protection_rules.query.graphql';
import deleteContainerProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/delete_container_protection_rule.mutation.graphql';
import updateContainerProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_container_registry_protection_rule.mutation.graphql';
import {
  containerProtectionRulesData,
  containerProtectionRuleQueryPayload,
  deleteContainerProtectionRuleMutationPayload,
  updateContainerProtectionRuleMutationPayload,
} from '../mock_data';

Vue.use(VueApollo);

describe('Container protection rules project settings', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
  };

  const $toast = { show: jest.fn() };

  const findSettingsBlock = () => wrapper.findComponent(SettingsBlock);
  const findTable = () =>
    extendedWrapper(wrapper.findByRole('table', { name: /protected containers/i }));
  const findTableBody = () => extendedWrapper(findTable().findAllByRole('rowgroup').at(1));
  const findTableLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTableRow = (i) => extendedWrapper(findTableBody().findAllByRole('row').at(i));
  const findTableRowButtonDelete = (i) => findTableRow(i).findByRole('button', { name: /delete/i });
  const findAddProtectionRuleForm = () => wrapper.findComponent(ContainerProtectionRuleForm);
  const findAddProtectionRuleFormSubmitButton = () =>
    wrapper.findByRole('button', { name: /add protection rule/i });
  const findAlert = () => wrapper.findByRole('alert');
  const findModal = () => wrapper.findComponent(GlModal);

  const mountComponent = (mountFn = mountExtended, provide = defaultProvidedValues, config) => {
    wrapper = mountFn(ContainerProtectionRules, {
      stubs: {
        SettingsBlock,
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
    containerProtectionRuleQueryResolver = jest
      .fn()
      .mockResolvedValue(containerProtectionRuleQueryPayload()),
    deleteContainerProtectionRuleMutationResolver = jest
      .fn()
      .mockResolvedValue(deleteContainerProtectionRuleMutationPayload()),
    updateContainerProtectionRuleMutationResolver = jest
      .fn()
      .mockResolvedValue(updateContainerProtectionRuleMutationPayload()),
    config = {},
  } = {}) => {
    const requestHandlers = [
      [ContainerProtectionRuleQuery, containerProtectionRuleQueryResolver],
      [deleteContainerProtectionRuleMutation, deleteContainerProtectionRuleMutationResolver],
      [updateContainerProtectionRuleMutation, updateContainerProtectionRuleMutationResolver],
    ];

    fakeApollo = createMockApollo(requestHandlers);

    mountComponent(mountFn, provide, {
      apolloProvider: fakeApollo,
      ...config,
    });
  };

  it('renders the setting block with table', async () => {
    createComponent();

    await waitForPromises();

    expect(findSettingsBlock().exists()).toBe(true);
    expect(findTable().exists()).toBe(true);
  });

  describe('table "container protection rules"', () => {
    const findTableRowCell = (i, j) => extendedWrapper(findTableRow(i).findAllByRole('cell').at(j));
    const findTableRowCellCombobox = (i, j) => findTableRowCell(i, j).findByRole('combobox');
    const findTableRowCellComboboxSelectedOption = (i, j) =>
      findTableRowCellCombobox(i, j).element.selectedOptions.item(0);

    it('renders table with container protection rules', async () => {
      createComponent();

      await waitForPromises();

      expect(findTable().exists()).toBe(true);

      containerProtectionRuleQueryPayload().data.project.containerRegistryProtectionRules.nodes.forEach(
        (protectionRule, i) => {
          expect(findTableRowCell(i, 0).text()).toBe(protectionRule.repositoryPathPattern);
          expect(findTableRowCellComboboxSelectedOption(i, 1).text).toBe('Maintainer');
          expect(findTableRowCellComboboxSelectedOption(i, 2).text).toBe('Maintainer');
        },
      );
    });

    it('renders table with container protection rule with blank minimumAccessLevelForDelete', async () => {
      const containerProtectionRuleQueryResolver = jest.fn().mockResolvedValue(
        containerProtectionRuleQueryPayload({
          nodes: [{ ...containerProtectionRulesData[0], minimumAccessLevelForDelete: null }],
        }),
      );
      createComponent({ containerProtectionRuleQueryResolver });

      await waitForPromises();

      expect(findTableRowCell(0, 0).text()).toBe(
        containerProtectionRulesData[0].repositoryPathPattern,
      );
      expect(findTableRowCellComboboxSelectedOption(0, 1).text).toBe('Maintainer');
      expect(findTableRowCellComboboxSelectedOption(0, 2).text).toBe('Developer (default)');
    });

    it('displays table in busy state and shows loading icon inside table', async () => {
      createComponent();

      expect(findTableLoadingIcon().exists()).toBe(true);
      expect(findTableLoadingIcon().attributes('aria-label')).toBe('Loading');

      expect(findTable().attributes('aria-busy')).toBe('true');

      await waitForPromises();

      expect(findTableLoadingIcon().exists()).toBe(false);
      expect(findTable().attributes('aria-busy')).toBe('false');
    });

    it('calls graphql api query', () => {
      const containerProtectionRuleQueryResolver = jest
        .fn()
        .mockResolvedValue(containerProtectionRuleQueryPayload());
      createComponent({ containerProtectionRuleQueryResolver });

      expect(containerProtectionRuleQueryResolver).toHaveBeenCalledWith(
        expect.objectContaining({ projectPath: defaultProvidedValues.projectPath }),
      );
    });

    it('shows alert when graphql api query failed', async () => {
      const graphqlErrorMessage = 'Error when requesting graphql api';
      const containerProtectionRuleQueryResolver = jest
        .fn()
        .mockRejectedValue(new Error(graphqlErrorMessage));
      createComponent({ containerProtectionRuleQueryResolver });

      await waitForPromises();

      expect(findAlert().isVisible()).toBe(true);
      expect(findAlert().text()).toBe(graphqlErrorMessage);
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
        const containerProtectionRuleQueryResolver = jest
          .fn()
          .mockResolvedValue(containerProtectionRuleQueryPayload());
        createComponent({ containerProtectionRuleQueryResolver });

        expect(containerProtectionRuleQueryResolver).toHaveBeenCalledWith(
          expect.objectContaining({
            projectPath: defaultProvidedValues.projectPath,
            first: 10,
          }),
        );
      });

      it('show alert when grapqhl fails', () => {
        const containerProtectionRuleQueryResolver = jest
          .fn()
          .mockResolvedValue(containerProtectionRuleQueryPayload());
        createComponent({ containerProtectionRuleQueryResolver });

        expect(containerProtectionRuleQueryResolver).toHaveBeenCalledWith(
          expect.objectContaining({
            projectPath: defaultProvidedValues.projectPath,
            first: 10,
          }),
        );
      });

      describe('when button "Previous" is clicked', () => {
        const containerProtectionRuleQueryResolver = jest
          .fn()
          .mockResolvedValueOnce(
            containerProtectionRuleQueryPayload({
              nodes: containerProtectionRulesData.slice(10),
              pageInfo: {
                hasNextPage: false,
                hasPreviousPage: true,
                startCursor: '10',
                endCursor: '16',
              },
            }),
          )
          .mockResolvedValueOnce(containerProtectionRuleQueryPayload());

        const findPaginationButtonPrev = () =>
          extendedWrapper(findPagination()).findByRole('button', { name: /previous/i });

        beforeEach(async () => {
          createComponent({ containerProtectionRuleQueryResolver });

          await waitForPromises();

          findPaginationButtonPrev().trigger('click');
        });

        it('sends a second graphql api query with new pagination params', () => {
          expect(containerProtectionRuleQueryResolver).toHaveBeenCalledTimes(2);
          expect(containerProtectionRuleQueryResolver).toHaveBeenLastCalledWith(
            expect.objectContaining({
              before: '10',
              last: 10,
              projectPath: 'path',
            }),
          );
        });
      });

      describe('when button "Next" is clicked', () => {
        const containerProtectionRuleQueryResolver = jest
          .fn()
          .mockResolvedValueOnce(containerProtectionRuleQueryPayload())
          .mockResolvedValueOnce(
            containerProtectionRuleQueryPayload({
              nodes: containerProtectionRulesData.slice(10),
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
          createComponent({ containerProtectionRuleQueryResolver });

          await waitForPromises();

          findPaginationButtonNext().trigger('click');
        });

        it('sends a second graphql api query with new pagination params', () => {
          expect(containerProtectionRuleQueryResolver).toHaveBeenCalledTimes(2);
          expect(containerProtectionRuleQueryResolver).toHaveBeenLastCalledWith(
            expect.objectContaining({
              after: '10',
              first: 10,
              projectPath: 'path',
            }),
          );
        });
      });
    });

    describe.each`
      comboboxName                         | minimumAccessLevelAttribute
      ${'Minimum access level for push'}   | ${'minimumAccessLevelForPush'}
      ${'Minimum access level for delete'} | ${'minimumAccessLevelForDelete'}
    `(
      'column "$comboboxName" with selectbox (combobox)',
      ({ comboboxName, minimumAccessLevelAttribute }) => {
        const findComboboxInTableRow = (i) =>
          extendedWrapper(findTableRow(i).findByRole('combobox', { name: comboboxName }));
        const findAllComboboxesInTableRow = (i) =>
          extendedWrapper(findTableRow(i).findAllByRole('combobox'));

        it('contains correct access level as options', async () => {
          createComponent();

          await waitForPromises();

          expect(findComboboxInTableRow(0).isVisible()).toBe(true);
          expect(findComboboxInTableRow(0).attributes('disabled')).toBeUndefined();
          expect(findComboboxInTableRow(0).element.value).toBe(
            containerProtectionRulesData[0][minimumAccessLevelAttribute],
          );

          const accessLevelOptions = findComboboxInTableRow(0)
            .findAllComponents('option')
            .wrappers.map((w) => w.text());

          expect(accessLevelOptions).toEqual([
            'Developer (default)',
            'Maintainer',
            'Owner',
            'Admin',
          ]);
        });

        describe('when value changes', () => {
          const accessLevelValueOwner = 'OWNER';
          const accessLevelValueMaintainer = 'MAINTAINER';

          it('only changes the value of the selectbox in the same row', async () => {
            createComponent();

            await waitForPromises();

            expect(findComboboxInTableRow(0).props('value')).toBe(accessLevelValueMaintainer);
            expect(findComboboxInTableRow(1).props('value')).toBe(accessLevelValueMaintainer);

            await findComboboxInTableRow(0).setValue(accessLevelValueOwner);

            expect(findComboboxInTableRow(0).props('value')).toBe(accessLevelValueOwner);
            expect(findComboboxInTableRow(1).props('value')).toBe(accessLevelValueMaintainer);
          });

          it('sends graphql mutation', async () => {
            const updateContainerProtectionRuleMutationResolver = jest
              .fn()
              .mockResolvedValue(updateContainerProtectionRuleMutationPayload());

            createComponent({ updateContainerProtectionRuleMutationResolver });

            await waitForPromises();

            await findComboboxInTableRow(0).setValue(accessLevelValueOwner);

            expect(updateContainerProtectionRuleMutationResolver).toHaveBeenCalledTimes(1);
            expect(updateContainerProtectionRuleMutationResolver).toHaveBeenCalledWith({
              input: {
                id: containerProtectionRulesData[0].id,
                [minimumAccessLevelAttribute]: accessLevelValueOwner,
              },
            });
          });

          it('disables all fields in relevant row when graphql mutation is in progress', async () => {
            createComponent();

            await waitForPromises();

            await findComboboxInTableRow(0).setValue(accessLevelValueOwner);

            findAllComboboxesInTableRow(0).wrappers.forEach((combobox) =>
              expect(combobox.props('disabled')).toBe(true),
            );
            expect(findTableRowButtonDelete(0).props('disabled')).toBe(true);
            findAllComboboxesInTableRow(1).wrappers.forEach((combobox) =>
              expect(combobox.props('disabled')).toBe(false),
            );
            expect(findTableRowButtonDelete(1).props('disabled')).toBe(false);

            await waitForPromises();

            findAllComboboxesInTableRow(0).wrappers.forEach((combobox) =>
              expect(combobox.props('disabled')).toBe(false),
            );
            expect(findTableRowButtonDelete(0).props('disabled')).toBe(false);
            findAllComboboxesInTableRow(1).wrappers.forEach((combobox) =>
              expect(combobox.props('disabled')).toBe(false),
            );
            expect(findTableRowButtonDelete(1).props('disabled')).toBe(false);
          });

          it('handles erroneous graphql mutation', async () => {
            const updateContainerProtectionRuleMutationResolver = jest
              .fn()
              .mockRejectedValue(new Error('error'));

            createComponent({ updateContainerProtectionRuleMutationResolver });

            await waitForPromises();

            await findComboboxInTableRow(0).setValue(accessLevelValueOwner);

            await waitForPromises();

            expect(findAlert().isVisible()).toBe(true);
            expect(findAlert().text()).toBe('error');
          });

          it('handles graphql mutation with error response', async () => {
            const serverErrorMessage = 'Server error message';
            const updateContainerProtectionRuleMutationResolver = jest.fn().mockResolvedValue(
              updateContainerProtectionRuleMutationPayload({
                containerRegistryProtectionRule: null,
                errors: [serverErrorMessage],
              }),
            );

            createComponent({ updateContainerProtectionRuleMutationResolver });

            await waitForPromises();

            await findComboboxInTableRow(0).setValue(accessLevelValueOwner);

            await waitForPromises();

            expect(findAlert().isVisible()).toBe(true);
            expect(findAlert().text()).toBe(serverErrorMessage);
          });

          it('shows a toast with success message', async () => {
            createComponent();

            await waitForPromises();

            await findComboboxInTableRow(0).setValue(accessLevelValueOwner);

            await waitForPromises();

            expect($toast.show).toHaveBeenCalledWith('Container protection rule updated.');
          });
        });
      },
    );

    describe('column "rowActions"', () => {
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
            expect(findModal().props('title')).toBe('Delete container protection rule?');
            expect(findModal().text()).toContain(
              'Users with at least the Developer role for this project will be able to push and delete container images to this repository path.',
            );
          });
        });
      });
    });
  });

  describe('modal "confirmation for delete action"', () => {
    const createComponentAndClickButtonDeleteInTableRow = async ({
      tableRowIndex = 0,
      deleteContainerProtectionRuleMutationResolver = jest
        .fn()
        .mockResolvedValue(deleteContainerProtectionRuleMutationPayload()),
    } = {}) => {
      createComponent({ deleteContainerProtectionRuleMutationResolver });

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
        const deleteContainerProtectionRuleMutationResolver = jest
          .fn()
          .mockResolvedValue(deleteContainerProtectionRuleMutationPayload());

        await createComponentAndClickButtonDeleteInTableRow({
          deleteContainerProtectionRuleMutationResolver,
        });

        await clickOnModalPrimaryBtn();

        expect(deleteContainerProtectionRuleMutationResolver).toHaveBeenCalledTimes(1);
        expect(deleteContainerProtectionRuleMutationResolver).toHaveBeenCalledWith({
          input: { id: containerProtectionRulesData[0].id },
        });
      });

      it('handles erroneous graphql mutation', async () => {
        const alertErrorMessage = 'Client error message';
        const deleteContainerProtectionRuleMutationResolver = jest
          .fn()
          .mockRejectedValue(new Error(alertErrorMessage));

        await createComponentAndClickButtonDeleteInTableRow({
          deleteContainerProtectionRuleMutationResolver,
        });

        await clickOnModalPrimaryBtn();

        await waitForPromises();

        expect(findAlert().isVisible()).toBe(true);
        expect(findAlert().text()).toBe(alertErrorMessage);
      });

      it('handles graphql mutation with error response', async () => {
        const alertErrorMessage = 'Server error message';
        const deleteContainerProtectionRuleMutationResolver = jest.fn().mockResolvedValue(
          deleteContainerProtectionRuleMutationPayload({
            containerRegistryProtectionRule: null,
            errors: [alertErrorMessage],
          }),
        );

        await createComponentAndClickButtonDeleteInTableRow({
          deleteContainerProtectionRuleMutationResolver,
        });

        await clickOnModalPrimaryBtn();

        await waitForPromises();

        expect(findAlert().isVisible()).toBe(true);
        expect(findAlert().text()).toBe(alertErrorMessage);
      });

      it('refetches package protection rules after successful graphql mutation', async () => {
        const deleteContainerProtectionRuleMutationResolver = jest
          .fn()
          .mockResolvedValue(deleteContainerProtectionRuleMutationPayload());

        const containerProtectionRuleQueryResolver = jest
          .fn()
          .mockResolvedValue(containerProtectionRuleQueryPayload());

        createComponent({
          containerProtectionRuleQueryResolver,
          deleteContainerProtectionRuleMutationResolver,
        });

        await waitForPromises();

        expect(containerProtectionRuleQueryResolver).toHaveBeenCalledTimes(1);

        await findTableRowButtonDelete(0).trigger('click');

        await clickOnModalPrimaryBtn();

        await waitForPromises();

        expect(containerProtectionRuleQueryResolver).toHaveBeenCalledTimes(2);
      });

      it('shows a toast with success message', async () => {
        await createComponentAndClickButtonDeleteInTableRow();

        await clickOnModalPrimaryBtn();

        await waitForPromises();

        expect($toast.show).toHaveBeenCalledWith('Container protection rule deleted.');
      });
    });
  });

  describe('button "Add protection rule"', () => {
    it('button exists', async () => {
      createComponent();

      await waitForPromises();

      expect(findAddProtectionRuleFormSubmitButton().isVisible()).toBe(true);
    });

    it('does not initially render form "add protection rule"', async () => {
      createComponent();

      await waitForPromises();

      expect(findAddProtectionRuleFormSubmitButton().isVisible()).toBe(true);
      expect(findAddProtectionRuleForm().exists()).toBe(false);
    });

    describe('when button is clicked', () => {
      beforeEach(async () => {
        createComponent();

        await waitForPromises();

        await findAddProtectionRuleFormSubmitButton().trigger('click');
      });

      it('renders form "add protection rule"', () => {
        expect(findAddProtectionRuleForm().isVisible()).toBe(true);
      });

      it('disables the button "add protection rule"', () => {
        expect(findAddProtectionRuleFormSubmitButton().attributes('disabled')).toBeDefined();
      });
    });
  });

  describe('form "add protection rule"', () => {
    let containerProtectionRuleQueryResolver;

    beforeEach(async () => {
      containerProtectionRuleQueryResolver = jest
        .fn()
        .mockResolvedValue(containerProtectionRuleQueryPayload());

      createComponent({ containerProtectionRuleQueryResolver });

      await waitForPromises();

      await findAddProtectionRuleFormSubmitButton().trigger('click');
    });

    it('handles event "submit"', async () => {
      await findAddProtectionRuleForm().vm.$emit('submit');

      expect(containerProtectionRuleQueryResolver).toHaveBeenCalledTimes(2);

      expect(findAddProtectionRuleForm().exists()).toBe(false);
      expect(findAddProtectionRuleFormSubmitButton().attributes('disabled')).not.toBeDefined();
    });

    it('handles event "cancel"', async () => {
      await findAddProtectionRuleForm().vm.$emit('cancel');

      expect(containerProtectionRuleQueryResolver).toHaveBeenCalledTimes(1);

      expect(findAddProtectionRuleForm().exists()).toBe(false);
      expect(findAddProtectionRuleFormSubmitButton().attributes()).not.toHaveProperty('disabled');
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

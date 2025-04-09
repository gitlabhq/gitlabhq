import { GlLoadingIcon, GlKeysetPagination, GlModal, GlTable } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { getBinding } from 'helpers/vue_mock_directive';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import ContainerProtectionRepositoryRuleForm from '~/packages_and_registries/settings/project/components/container_protection_repository_rule_form.vue';
import ContainerProtectionRepositoryRules from '~/packages_and_registries/settings/project/components/container_protection_repository_rules.vue';
import ContainerProtectionRepositoryRuleQuery from '~/packages_and_registries/settings/project/graphql/queries/get_container_protection_repository_rules.query.graphql';
import deleteContainerProtectionRepositoryRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/delete_container_protection_repository_rule.mutation.graphql';
import updateContainerProtectionRepositoryRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_container_protection_repository_rule.mutation.graphql';
import {
  containerProtectionRepositoryRulesData,
  containerProtectionRepositoryRuleQueryPayload,
  deleteContainerProtectionRepositoryRuleMutationPayload,
  updateContainerProtectionRepositoryRuleMutationPayload,
} from '../mock_data';

Vue.use(VueApollo);

describe('Container protection repository rules project settings', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
    glFeatures: {
      containerRegistryProtectedContainersDelete: true,
    },
  };

  const $toast = { show: jest.fn() };

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findEmptyText = () => wrapper.findByText('No container repositories are protected.');
  const findTable = () =>
    extendedWrapper(wrapper.findByRole('table', { name: /protected container repositories/i }));
  const findTableBody = () => extendedWrapper(findTable().findAllByRole('rowgroup').at(1));
  const findTableLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTableRow = (i) => extendedWrapper(findTableBody().findAllByRole('row').at(i));
  const findTableRowButtonDelete = (i) => findTableRow(i).findByRole('button', { name: /delete/i });
  const findAddProtectionRuleForm = () =>
    wrapper.findComponent(ContainerProtectionRepositoryRuleForm);
  const findAddProtectionRuleFormSubmitButton = () =>
    wrapper.findByRole('button', { name: /add protection rule/i });
  const findAlert = () => wrapper.findByRole('alert');
  const findModal = () => wrapper.findComponent(GlModal);

  const mountComponent = (mountFn = mountExtended, provide = defaultProvidedValues, config) => {
    wrapper = mountFn(ContainerProtectionRepositoryRules, {
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
    containerProtectionRepositoryRuleQueryResolver = jest
      .fn()
      .mockResolvedValue(containerProtectionRepositoryRuleQueryPayload()),
    deleteContainerProtectionRepositoryRuleMutationResolver = jest
      .fn()
      .mockResolvedValue(deleteContainerProtectionRepositoryRuleMutationPayload()),
    updateContainerProtectionRepositoryRuleMutationResolver = jest
      .fn()
      .mockResolvedValue(updateContainerProtectionRepositoryRuleMutationPayload()),
    config = {},
  } = {}) => {
    const requestHandlers = [
      [ContainerProtectionRepositoryRuleQuery, containerProtectionRepositoryRuleQueryResolver],
      [
        deleteContainerProtectionRepositoryRuleMutation,
        deleteContainerProtectionRepositoryRuleMutationResolver,
      ],
      [
        updateContainerProtectionRepositoryRuleMutation,
        updateContainerProtectionRepositoryRuleMutationResolver,
      ],
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

    expect(findCrudComponent().props()).toMatchObject({
      title: 'Protected container repositories',
      toggleText: 'Add protection rule',
    });
    expect(findTable().exists()).toBe(true);
  });

  it('hides table when no protection rules exist', async () => {
    createComponent({
      containerProtectionRepositoryRuleQueryResolver: jest.fn().mockResolvedValue(
        containerProtectionRepositoryRuleQueryPayload({
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

  describe('table "container protection rules"', () => {
    const findTableRowCell = (i, j) => extendedWrapper(findTableRow(i).findAllByRole('cell').at(j));
    const findTableRowCellCombobox = (i, j) => findTableRowCell(i, j).findByRole('combobox');
    const findTableRowCellComboboxSelectedOption = (i, j) =>
      findTableRowCellCombobox(i, j).element.selectedOptions.item(0);

    it('renders table with container protection rules', async () => {
      createComponent();

      await waitForPromises();

      expect(findTable().exists()).toBe(true);

      containerProtectionRepositoryRuleQueryPayload().data.project.containerProtectionRepositoryRules.nodes.forEach(
        (protectionRule, i) => {
          expect(findTableRowCell(i, 0).text()).toBe(protectionRule.repositoryPathPattern);
          expect(findTableRowCellComboboxSelectedOption(i, 1).text).toBe('Maintainer');
          expect(findTableRowCellComboboxSelectedOption(i, 2).text).toBe('Maintainer');
        },
      );
    });

    it('renders table with container protection rule with blank minimumAccessLevelForDelete', async () => {
      const containerProtectionRepositoryRuleQueryResolver = jest.fn().mockResolvedValue(
        containerProtectionRepositoryRuleQueryPayload({
          nodes: [
            { ...containerProtectionRepositoryRulesData[0], minimumAccessLevelForDelete: null },
          ],
        }),
      );
      createComponent({ containerProtectionRepositoryRuleQueryResolver });

      await waitForPromises();

      expect(findTableRowCell(0, 0).text()).toBe(
        containerProtectionRepositoryRulesData[0].repositoryPathPattern,
      );
      expect(findTableRowCellComboboxSelectedOption(0, 1).text).toBe('Maintainer');
      expect(findTableRowCellComboboxSelectedOption(0, 2).text).toBe('Developer (default)');
    });

    it('shows loading icon', () => {
      createComponent();

      expect(findTableLoadingIcon().exists()).toBe(true);
      expect(findTableLoadingIcon().attributes('aria-label')).toBe('Loading');
    });

    it('calls graphql api query', () => {
      const containerProtectionRepositoryRuleQueryResolver = jest
        .fn()
        .mockResolvedValue(containerProtectionRepositoryRuleQueryPayload());
      createComponent({ containerProtectionRepositoryRuleQueryResolver });

      expect(containerProtectionRepositoryRuleQueryResolver).toHaveBeenCalledWith(
        expect.objectContaining({ projectPath: defaultProvidedValues.projectPath }),
      );
    });

    it('shows alert when graphql api query failed', async () => {
      const graphqlErrorMessage = 'Error when requesting graphql api';
      const containerProtectionRepositoryRuleQueryResolver = jest
        .fn()
        .mockRejectedValue(new Error(graphqlErrorMessage));
      createComponent({ containerProtectionRepositoryRuleQueryResolver });

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
        const containerProtectionRepositoryRuleQueryResolver = jest
          .fn()
          .mockResolvedValue(containerProtectionRepositoryRuleQueryPayload());
        createComponent({ containerProtectionRepositoryRuleQueryResolver });

        expect(containerProtectionRepositoryRuleQueryResolver).toHaveBeenCalledWith(
          expect.objectContaining({
            projectPath: defaultProvidedValues.projectPath,
            first: 10,
          }),
        );
      });

      it('show alert when grapqhl fails', () => {
        const containerProtectionRepositoryRuleQueryResolver = jest
          .fn()
          .mockResolvedValue(containerProtectionRepositoryRuleQueryPayload());
        createComponent({ containerProtectionRepositoryRuleQueryResolver });

        expect(containerProtectionRepositoryRuleQueryResolver).toHaveBeenCalledWith(
          expect.objectContaining({
            projectPath: defaultProvidedValues.projectPath,
            first: 10,
          }),
        );
      });

      describe('when button "Previous" is clicked', () => {
        const containerProtectionRepositoryRuleQueryResolver = jest
          .fn()
          .mockResolvedValueOnce(
            containerProtectionRepositoryRuleQueryPayload({
              nodes: containerProtectionRepositoryRulesData.slice(10),
              pageInfo: {
                hasNextPage: false,
                hasPreviousPage: true,
                startCursor: '10',
                endCursor: '16',
              },
            }),
          )
          .mockResolvedValueOnce(containerProtectionRepositoryRuleQueryPayload());

        const findPaginationButtonPrev = () =>
          extendedWrapper(findPagination()).findByRole('button', { name: /previous/i });

        beforeEach(async () => {
          createComponent({ containerProtectionRepositoryRuleQueryResolver });

          await waitForPromises();

          findPaginationButtonPrev().trigger('click');
        });

        it('sends a second graphql api query with new pagination params', () => {
          expect(containerProtectionRepositoryRuleQueryResolver).toHaveBeenCalledTimes(2);
          expect(containerProtectionRepositoryRuleQueryResolver).toHaveBeenLastCalledWith(
            expect.objectContaining({
              before: '10',
              last: 10,
              projectPath: 'path',
            }),
          );
        });
      });

      describe('when button "Next" is clicked', () => {
        const containerProtectionRepositoryRuleQueryResolver = jest
          .fn()
          .mockResolvedValue(containerProtectionRepositoryRuleQueryPayload())
          .mockResolvedValueOnce(containerProtectionRepositoryRuleQueryPayload())
          .mockResolvedValueOnce(
            containerProtectionRepositoryRuleQueryPayload({
              nodes: containerProtectionRepositoryRulesData.slice(10),
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
          createComponent({ containerProtectionRepositoryRuleQueryResolver });

          await waitForPromises();

          findPaginationButtonNext().trigger('click');
        });

        it('sends a second graphql api query with new pagination params', () => {
          expect(containerProtectionRepositoryRuleQueryResolver).toHaveBeenCalledTimes(2);
          expect(containerProtectionRepositoryRuleQueryResolver).toHaveBeenLastCalledWith(
            expect.objectContaining({
              after: '10',
              first: 10,
              projectPath: 'path',
            }),
          );
        });

        it('displays table in busy state and shows loading icon inside table', async () => {
          expect(findTableLoadingIcon().exists()).toBe(true);
          expect(findTableLoadingIcon().attributes('aria-label')).toBe('Loading');

          expect(findTable().attributes('aria-busy')).toBe('true');

          await waitForPromises();

          expect(findTableLoadingIcon().exists()).toBe(false);
          expect(findTable().attributes('aria-busy')).toBe('false');
        });
      });
    });

    describe.each`
      comboboxName                                | minimumAccessLevelAttribute
      ${'minimum-access-level-for-push-select'}   | ${'minimumAccessLevelForPush'}
      ${'minimum-access-level-for-delete-select'} | ${'minimumAccessLevelForDelete'}
    `(
      'column "$comboboxName" with selectbox (combobox)',
      ({ comboboxName, minimumAccessLevelAttribute }) => {
        const findComboboxInTableRow = (i) =>
          extendedWrapper(wrapper.findAllByTestId(comboboxName).at(i));

        it('contains correct access level as options', async () => {
          createComponent();

          await waitForPromises();

          expect(findComboboxInTableRow(0).isVisible()).toBe(true);
          expect(findComboboxInTableRow(0).attributes('disabled')).toBeUndefined();
          expect(findComboboxInTableRow(0).element.value).toBe(
            containerProtectionRepositoryRulesData[0][minimumAccessLevelAttribute],
          );

          const accessLevelOptions = findComboboxInTableRow(0)
            .findAllComponents('option')
            .wrappers.map((w) => w.text());

          expect(accessLevelOptions).toEqual([
            'Developer (default)',
            'Maintainer',
            'Owner',
            'Administrator',
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

            await findComboboxInTableRow(0).findAll('option').at(2).setSelected();

            expect(findComboboxInTableRow(0).props('value')).toBe(accessLevelValueOwner);
            expect(findComboboxInTableRow(1).props('value')).toBe(accessLevelValueMaintainer);
          });

          it('sends graphql mutation', async () => {
            const updateContainerProtectionRepositoryRuleMutationResolver = jest
              .fn()
              .mockResolvedValue(updateContainerProtectionRepositoryRuleMutationPayload());

            createComponent({ updateContainerProtectionRepositoryRuleMutationResolver });

            await waitForPromises();

            await findComboboxInTableRow(0).findAll('option').at(2).setSelected();

            expect(updateContainerProtectionRepositoryRuleMutationResolver).toHaveBeenCalledTimes(
              1,
            );
            expect(updateContainerProtectionRepositoryRuleMutationResolver).toHaveBeenCalledWith({
              input: {
                id: containerProtectionRepositoryRulesData[0].id,
                [minimumAccessLevelAttribute]: accessLevelValueOwner,
              },
            });
          });

          it('sends graphql mutation with blank field valule for minimumAccessLevel', async () => {
            const updateContainerProtectionRepositoryRuleMutationResolver = jest
              .fn()
              .mockResolvedValue(updateContainerProtectionRepositoryRuleMutationPayload());

            createComponent({ updateContainerProtectionRepositoryRuleMutationResolver });

            await waitForPromises();

            await findComboboxInTableRow(0).findAll('option').at(0).setSelected();

            expect(updateContainerProtectionRepositoryRuleMutationResolver).toHaveBeenCalledTimes(
              1,
            );
            expect(updateContainerProtectionRepositoryRuleMutationResolver).toHaveBeenCalledWith({
              input: {
                id: containerProtectionRepositoryRulesData[0].id,
                [minimumAccessLevelAttribute]: null,
              },
            });
          });

          it('disables all fields in relevant row when graphql mutation is in progress', async () => {
            createComponent();

            await waitForPromises();

            await findComboboxInTableRow(0).findAll('option').at(2).setSelected();

            expect(findComboboxInTableRow(0).props('disabled')).toBe(true);
            expect(findTableRowButtonDelete(0).attributes('disabled')).toBe('disabled');

            expect(findComboboxInTableRow(1).props('disabled')).toBe(false);
            expect(findTableRowButtonDelete(1).attributes('disabled')).toBeUndefined();

            await waitForPromises();

            expect(findComboboxInTableRow(0).props('disabled')).toBe(false);
            expect(findTableRowButtonDelete(0).attributes('disabled')).toBeUndefined();

            expect(findComboboxInTableRow(1).props('disabled')).toBe(false);
            expect(findTableRowButtonDelete(1).attributes('disabled')).toBeUndefined();
          });

          it('handles erroneous graphql mutation', async () => {
            const updateContainerProtectionRepositoryRuleMutationResolver = jest
              .fn()
              .mockRejectedValue(new Error('error'));

            createComponent({ updateContainerProtectionRepositoryRuleMutationResolver });

            await waitForPromises();

            await findComboboxInTableRow(0).findAll('option').at(2).setSelected();

            await waitForPromises();

            expect(findAlert().isVisible()).toBe(true);
            expect(findAlert().text()).toBe('error');
          });

          it('handles graphql mutation with error response', async () => {
            const serverErrorMessage = 'Server error message';
            const updateContainerProtectionRepositoryRuleMutationResolver = jest
              .fn()
              .mockResolvedValue(
                updateContainerProtectionRepositoryRuleMutationPayload({
                  containerRegistryProtectionRule: null,
                  errors: [serverErrorMessage],
                }),
              );

            createComponent({ updateContainerProtectionRepositoryRuleMutationResolver });

            await waitForPromises();

            await findComboboxInTableRow(0).findAll('option').at(2).setSelected();

            await waitForPromises();

            expect(findAlert().isVisible()).toBe(true);
            expect(findAlert().text()).toBe(serverErrorMessage);
          });

          it('shows a toast with success message', async () => {
            createComponent();

            await waitForPromises();

            await findComboboxInTableRow(0).findAll('option').at(2).setSelected();

            await waitForPromises();

            expect($toast.show).toHaveBeenCalledWith('Container protection rule updated.');
          });
        });
      },
    );

    describe('when feature flag "containerRegistryProtectedContainersDelete" is disabled', () => {
      const provide = {
        ...defaultProvidedValues,
        glFeatures: {
          ...defaultProvidedValues.glFeatures,
          containerRegistryProtectedContainersDelete: false,
        },
      };

      describe('column "Minimum access level for push"', () => {
        const findComboboxInTableRow = (i) =>
          extendedWrapper(wrapper.findAllByTestId('minimum-access-level-for-push-select').at(i));

        it('contains correct access level as options without null', async () => {
          createComponent({ provide });

          await waitForPromises();

          expect(findComboboxInTableRow(0).isVisible()).toBe(true);
          expect(findComboboxInTableRow(0).attributes('disabled')).toBeUndefined();
          expect(findComboboxInTableRow(0).element.value).toBe(
            containerProtectionRepositoryRulesData[0].minimumAccessLevelForPush,
          );

          const accessLevelOptions = findComboboxInTableRow(0)
            .findAllComponents('option')
            .wrappers.map((w) => w.text());

          expect(accessLevelOptions).toEqual(['Maintainer', 'Owner', 'Administrator']);
        });
      });

      describe('column "Minimum access level for delete"', () => {
        const findTableColumnHeader = () =>
          wrapper.findByRole('columnheader', { name: /minimum access level for delete/i });

        it('does not show column "Minimum access level for delete"', async () => {
          createComponent({ provide });

          await waitForPromises();

          expect(findTableColumnHeader().exists()).toBe(false);
          expect(wrapper.findAllByTestId('minimum-access-level-for-delete-select')).toHaveLength(0);
        });
      });
    });

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
            expect(findModal().props('title')).toBe('Delete container repository protection rule?');
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
      deleteContainerProtectionRepositoryRuleMutationResolver = jest
        .fn()
        .mockResolvedValue(deleteContainerProtectionRepositoryRuleMutationPayload()),
    } = {}) => {
      createComponent({ deleteContainerProtectionRepositoryRuleMutationResolver });

      await waitForPromises();

      findTableRowButtonDelete(tableRowIndex).trigger('click');
    };

    describe('when modal button "primary" clicked', () => {
      const clickOnModalPrimaryBtn = () => findModal().vm.$emit('primary');

      it('disables the button when graphql mutation is executed', async () => {
        await createComponentAndClickButtonDeleteInTableRow();

        await clickOnModalPrimaryBtn();

        expect(findTableRowButtonDelete(0).attributes('disabled')).toBe('disabled');

        expect(findTableRowButtonDelete(1).attributes('disabled')).toBeUndefined();
      });

      it('sends graphql mutation', async () => {
        const deleteContainerProtectionRepositoryRuleMutationResolver = jest
          .fn()
          .mockResolvedValue(deleteContainerProtectionRepositoryRuleMutationPayload());

        await createComponentAndClickButtonDeleteInTableRow({
          deleteContainerProtectionRepositoryRuleMutationResolver,
        });

        await clickOnModalPrimaryBtn();

        expect(deleteContainerProtectionRepositoryRuleMutationResolver).toHaveBeenCalledTimes(1);
        expect(deleteContainerProtectionRepositoryRuleMutationResolver).toHaveBeenCalledWith({
          input: { id: containerProtectionRepositoryRulesData[0].id },
        });
      });

      it('handles erroneous graphql mutation', async () => {
        const alertErrorMessage = 'Client error message';
        const deleteContainerProtectionRepositoryRuleMutationResolver = jest
          .fn()
          .mockRejectedValue(new Error(alertErrorMessage));

        await createComponentAndClickButtonDeleteInTableRow({
          deleteContainerProtectionRepositoryRuleMutationResolver,
        });

        await clickOnModalPrimaryBtn();

        await waitForPromises();

        expect(findAlert().isVisible()).toBe(true);
        expect(findAlert().text()).toBe(alertErrorMessage);
      });

      it('handles graphql mutation with error response', async () => {
        const alertErrorMessage = 'Server error message';
        const deleteContainerProtectionRepositoryRuleMutationResolver = jest.fn().mockResolvedValue(
          deleteContainerProtectionRepositoryRuleMutationPayload({
            containerRegistryProtectionRule: null,
            errors: [alertErrorMessage],
          }),
        );

        await createComponentAndClickButtonDeleteInTableRow({
          deleteContainerProtectionRepositoryRuleMutationResolver,
        });

        await clickOnModalPrimaryBtn();

        await waitForPromises();

        expect(findAlert().isVisible()).toBe(true);
        expect(findAlert().text()).toBe(alertErrorMessage);
      });

      it('refetches package protection rules after successful graphql mutation', async () => {
        const deleteContainerProtectionRepositoryRuleMutationResolver = jest
          .fn()
          .mockResolvedValue(deleteContainerProtectionRepositoryRuleMutationPayload());

        const containerProtectionRepositoryRuleQueryResolver = jest
          .fn()
          .mockResolvedValue(containerProtectionRepositoryRuleQueryPayload());

        createComponent({
          containerProtectionRepositoryRuleQueryResolver,
          deleteContainerProtectionRepositoryRuleMutationResolver,
        });

        await waitForPromises();

        expect(containerProtectionRepositoryRuleQueryResolver).toHaveBeenCalledTimes(1);

        await findTableRowButtonDelete(0).trigger('click');

        await clickOnModalPrimaryBtn();

        await waitForPromises();

        expect(containerProtectionRepositoryRuleQueryResolver).toHaveBeenCalledTimes(2);
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

      it('hides the button "add protection rule"', () => {
        expect(findAddProtectionRuleFormSubmitButton().exists()).toBe(false);
      });
    });
  });

  describe('form "add protection rule"', () => {
    let containerProtectionRepositoryRuleQueryResolver;

    beforeEach(async () => {
      containerProtectionRepositoryRuleQueryResolver = jest
        .fn()
        .mockResolvedValue(containerProtectionRepositoryRuleQueryPayload());

      createComponent({ containerProtectionRepositoryRuleQueryResolver });

      await waitForPromises();

      await findAddProtectionRuleFormSubmitButton().trigger('click');
    });

    it('handles event "submit"', async () => {
      await findAddProtectionRuleForm().vm.$emit('submit');

      expect(containerProtectionRepositoryRuleQueryResolver).toHaveBeenCalledTimes(2);

      expect(findAddProtectionRuleForm().exists()).toBe(false);
      expect(findAddProtectionRuleFormSubmitButton().attributes('disabled')).not.toBeDefined();
    });

    it('handles event "cancel"', async () => {
      await findAddProtectionRuleForm().vm.$emit('cancel');

      expect(containerProtectionRepositoryRuleQueryResolver).toHaveBeenCalledTimes(1);

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

import { GlLoadingIcon, GlKeysetPagination, GlModal, GlTable, GlDrawer } from '@gitlab/ui';

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { getBinding } from 'helpers/vue_mock_directive';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import ContainerProtectionRepositoryRuleForm from '~/packages_and_registries/settings/project/components/container_protection_repository_rule_form.vue';
import ContainerProtectionRepositoryRules from '~/packages_and_registries/settings/project/components/container_protection_repository_rules.vue';
import containerProtectionRepositoryRuleQuery from '~/packages_and_registries/settings/project/graphql/queries/get_container_protection_repository_rules.query.graphql';
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
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findDrawerTitle = () => wrapper.findComponent(GlDrawer).find('h2');
  const findEmptyText = () => wrapper.findByText('No container repositories are protected.');
  const findTable = () =>
    extendedWrapper(wrapper.findByRole('table', { name: /protected container repositories/i }));
  const findTableBody = () => extendedWrapper(findTable().findAllByRole('rowgroup').at(1));
  const findTableLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTableRow = (i) => extendedWrapper(findTableBody().findAllByRole('row').at(i));
  const findTableRowMinimumAccessLevelForPush = (i) =>
    findTableRow(i).findByTestId('minimum-access-level-push-value');
  const findTableRowMinimumAccessLevelForDelete = (i) =>
    findTableRow(i).findByTestId('minimum-access-level-delete-value');
  const findTableRowButtonDelete = (i) => findTableRow(i).findByRole('button', { name: /delete/i });
  const findTableRowButtonEdit = (i) => findTableRow(i).findByRole('button', { name: /edit/i });
  const findProtectionRuleForm = () => wrapper.findComponent(ContainerProtectionRepositoryRuleForm);
  const findAddProtectionRuleButton = () =>
    wrapper.findByRole('button', { name: /add protection rule/i });
  const findAlert = () => wrapper.findByRole('alert');
  const findModal = () => wrapper.findComponent(GlModal);

  const mountComponent = (mountFn = mountExtended, provide = defaultProvidedValues, config) => {
    wrapper = mountFn(ContainerProtectionRepositoryRules, {
      stubs: {
        GlModal: true,
        CrudComponent,
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
      [containerProtectionRepositoryRuleQuery, containerProtectionRepositoryRuleQueryResolver],
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

  it('renders the setting block with title, description and table', async () => {
    createComponent();

    await waitForPromises();

    expect(findCrudComponent().props()).toMatchObject({
      title: 'Protected container repositories',
      toggleText: 'Add protection rule',
      description:
        'When a container repository is protected, only users with specific roles can push and delete container images. This helps prevent unauthorized modifications.',
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

  it('drawer is hidden', async () => {
    createComponent();

    await waitForPromises();

    expect(findDrawer().props('open')).toBe(false);
  });

  describe('table "container protection rules"', () => {
    const findTableRowCell = (i, j) => extendedWrapper(findTableRow(i).findAllByRole('cell').at(j));

    it('renders table with container protection rules', async () => {
      createComponent();

      await waitForPromises();

      expect(findTable().exists()).toBe(true);

      containerProtectionRepositoryRuleQueryPayload().data.project.containerProtectionRepositoryRules.nodes.forEach(
        (protectionRule, i) => {
          expect(findTableRowCell(i, 0).text()).toBe(protectionRule.repositoryPathPattern);
          expect(findTableRowCell(i, 1).text()).toBe('Maintainer');
          expect(findTableRowCell(i, 2).text()).toBe('Maintainer');
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
      expect(findTableRowCell(0, 1).text()).toBe('Maintainer');
      expect(findTableRowCell(0, 2).text()).toBe('Developer (default)');
    });

    it('shows loading indicator', () => {
      createComponent();

      expect(findCrudComponent().props('isLoading')).toBe(true);
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

    describe('column "Minimum access level for push" and "Minimum access level for delete"', () => {
      it('contains correct access level as options', async () => {
        createComponent();
        await waitForPromises();

        expect(findTableRowMinimumAccessLevelForPush(0).text()).toBe('Maintainer');
        expect(findTableRowMinimumAccessLevelForDelete(0).text()).toBe('Maintainer');
      });

      it('renders correct value for blank value', async () => {
        const containerProtectionRepositoryRuleQueryResolver = jest.fn().mockResolvedValue(
          containerProtectionRepositoryRuleQueryPayload({
            nodes: [
              {
                ...containerProtectionRepositoryRulesData[0],
                minimumAccessLevelForPush: null,
                minimumAccessLevelForDelete: 'ADMIN',
              },
            ],
          }),
        );

        createComponent({ containerProtectionRepositoryRuleQueryResolver });

        await waitForPromises();

        expect(findTableRowMinimumAccessLevelForPush(0).text()).toBe('Developer (default)');
        expect(findTableRowMinimumAccessLevelForDelete(0).text()).toBe('Administrator');
      });

      describe('when feature flag "containerRegistryProtectedContainersDelete" is disabled', () => {
        const findTableHeaderColumnMinimumAccessLevelForDelete = () =>
          wrapper.findByRole('columnheader', { name: /minimum access level for delete/i });

        const provide = {
          ...defaultProvidedValues,
          glFeatures: {
            ...defaultProvidedValues.glFeatures,
            containerRegistryProtectedContainersDelete: false,
          },
        };

        it('still shows column "Minimum access level for push"', async () => {
          createComponent({ provide });
          await waitForPromises();

          expect(findTableRowMinimumAccessLevelForPush(0).isVisible()).toBe(true);
          expect(findTableRowMinimumAccessLevelForPush(0).text()).toBe('Maintainer');
        });

        it('does not show column "Minimum access level for delete"', async () => {
          createComponent({ provide });

          await waitForPromises();

          expect(findTableHeaderColumnMinimumAccessLevelForDelete().exists()).toBe(false);
          expect(findTableRowMinimumAccessLevelForDelete(0).exists()).toBe(false);
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

      it('refetches protection rules after successful graphql mutation', async () => {
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

  describe.each`
    description                                       | beforeFn                                                | rule                                         | title                     | toastMessage
    ${'when `Add protection rule` button is clicked'} | ${() => findAddProtectionRuleButton().trigger('click')} | ${null}                                      | ${'Add protection rule'}  | ${'Protection rule created.'}
    ${'when `Edit` button for a rule is clicked'}     | ${() => findTableRowButtonEdit(0).trigger('click')}     | ${containerProtectionRepositoryRulesData[0]} | ${'Edit protection rule'} | ${'Protection rule updated.'}
  `('$description', ({ beforeFn, title, rule, toastMessage }) => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();

      await beforeFn();
    });

    it('opens drawer', () => {
      expect(findDrawer().props('open')).toBe(true);
    });

    it(`sets the appropriate drawer title: ${title}`, () => {
      expect(findDrawerTitle().text()).toBe(title);
    });

    it('renders form', () => {
      expect(findProtectionRuleForm().props()).toStrictEqual({
        rule,
      });
    });

    describe('when drawer emits `close` event', () => {
      beforeEach(async () => {
        await findDrawer().vm.$emit('close');
      });

      it('closes drawer', () => {
        expect(findDrawer().props('open')).toBe(false);
      });
    });

    describe('when form emits `cancel` event', () => {
      beforeEach(async () => {
        await findProtectionRuleForm().vm.$emit('cancel');
      });

      it('closes drawer', () => {
        expect(findProtectionRuleForm().exists()).toBe(false);
        expect(findAddProtectionRuleButton().attributes('disabled')).not.toBeDefined();
        expect(findDrawer().props('open')).toBe(false);
      });
    });

    describe('when form emits `submit` event', () => {
      it('refetches protection rules after successful graphql mutation', async () => {
        const containerProtectionRepositoryRuleQueryResolver = jest
          .fn()
          .mockResolvedValue(containerProtectionRepositoryRuleQueryPayload());

        createComponent({ containerProtectionRepositoryRuleQueryResolver });

        await waitForPromises();

        expect(containerProtectionRepositoryRuleQueryResolver).toHaveBeenCalledTimes(1);

        await beforeFn();
        await findProtectionRuleForm().vm.$emit('submit');

        expect(findProtectionRuleForm().exists()).toBe(false);
        expect(findAddProtectionRuleButton().attributes('disabled')).not.toBeDefined();
        expect(findDrawer().props('open')).toBe(false);
        expect(containerProtectionRepositoryRuleQueryResolver).toHaveBeenCalledTimes(2);
        expect($toast.show).toHaveBeenCalledWith(toastMessage);
      });
    });
  });
});

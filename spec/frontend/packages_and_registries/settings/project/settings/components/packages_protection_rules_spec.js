import { GlDrawer, GlLoadingIcon, GlKeysetPagination, GlModal, GlTable } from '@gitlab/ui';
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
import {
  packagesProtectionRuleQueryPayload,
  packagesProtectionRulesData,
  deletePackagesProtectionRuleMutationPayload,
} from '../mock_data';

Vue.use(VueApollo);

describe('Packages protection rules project settings', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
    glFeatures: {
      packagesProtectedPackagesDelete: true,
    },
  };

  const $toast = { show: jest.fn() };

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findDrawerTitle = () => wrapper.findComponent(GlDrawer).find('h2');
  const findEmptyText = () => wrapper.findByText('No packages are protected.');
  const findTable = () =>
    extendedWrapper(wrapper.findByRole('table', { name: /protected packages/i }));
  const findTableBody = () => extendedWrapper(findTable().findAllByRole('rowgroup').at(1));
  const findTableRow = (i) => extendedWrapper(findTableBody().findAllByRole('row').at(i));
  const findMinimumAccessLevelForPushInTableRow = (i) =>
    findTableRow(i).findByTestId('minimum-access-level-push-value');
  const findMinimumAccessLevelForDeleteInTableRow = (i) =>
    findTableRow(i).findByTestId('minimum-access-level-delete-value');
  const findTableRowButtonDelete = (i) =>
    extendedWrapper(wrapper.findAllByTestId('delete-rule-btn').at(i));
  const findTableLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTableRowButtonEdit = (i) => findTableRow(i).findByRole('button', { name: /edit/i });
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
    config = {},
  } = {}) => {
    const requestHandlers = [
      [packagesProtectionRuleQuery, packagesProtectionRuleQueryResolver],
      [deletePackagesProtectionRuleMutation, deletePackagesProtectionRuleMutationResolver],
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

  it('drawer is hidden', () => {
    createComponent();

    expect(findDrawer().props('open')).toBe(false);
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

    describe('column "Minimum access level for push"', () => {
      it('renders correct value for blank value', async () => {
        const packagesProtectionRuleQueryResolver = jest.fn().mockResolvedValue(
          packagesProtectionRuleQueryPayload({
            nodes: [
              {
                ...packagesProtectionRulesData[0],
                minimumAccessLevelForPush: null,
                minimumAccessLevelForDelete: 'ADMIN',
              },
            ],
          }),
        );

        createComponent({ packagesProtectionRuleQueryResolver });

        await waitForPromises();

        expect(findMinimumAccessLevelForPushInTableRow(0).text()).toContain('Developer (default)');
        expect(findMinimumAccessLevelForDeleteInTableRow(0).text()).toContain('Administrator');
      });
    });

    describe('column "Minimum access level for delete"', () => {
      it('renders correct value for blank value', async () => {
        const packagesProtectionRuleQueryResolver = jest.fn().mockResolvedValue(
          packagesProtectionRuleQueryPayload({
            nodes: [
              {
                ...packagesProtectionRulesData[0],
                minimumAccessLevelForPush: 'OWNER',
                minimumAccessLevelForDelete: null,
              },
            ],
          }),
        );

        createComponent({ packagesProtectionRuleQueryResolver });

        await waitForPromises();

        expect(findMinimumAccessLevelForPushInTableRow(0).text()).toContain('Owner');
        expect(findMinimumAccessLevelForDeleteInTableRow(0).text()).toContain(
          'Maintainer (default)',
        );
      });

      describe('when feature flag packagesProtectedPackagesDelete is disabled', () => {
        const findTableColumnHeaderMinimumAccessLevelForDelete = () =>
          wrapper.findByRole('columnheader', { name: /minimum access level for delete/i });

        it('does not show column "Minimum access level for delete"', async () => {
          createComponent({
            provide: {
              ...defaultProvidedValues,
              glFeatures: {
                ...defaultProvidedValues.glFeatures,
                packagesProtectedPackagesDelete: false,
              },
            },
          });

          await waitForPromises();

          expect(findTableColumnHeaderMinimumAccessLevelForDelete().exists()).toBe(false);
          expect(findMinimumAccessLevelForDeleteInTableRow(0).exists()).toBe(false);
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

  describe.each`
    description                                       | beforeFn                                                | rule                              | title                     | toastMessage
    ${'when `Add protection rule` button is clicked'} | ${() => findAddProtectionRuleButton().trigger('click')} | ${null}                           | ${'Add protection rule'}  | ${'Package protection rule created.'}
    ${'when `Edit` button for a rule is clicked'}     | ${() => findTableRowButtonEdit(0).trigger('click')}     | ${packagesProtectionRulesData[0]} | ${'Edit protection rule'} | ${'Package protection rule updated.'}
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
        expect(findDrawer().props('open')).toBe(false);
      });
    });

    describe('when form emits `submit` event', () => {
      it('refetches protection rules after successful graphql mutation', async () => {
        const packagesProtectionRuleQueryResolver = jest
          .fn()
          .mockResolvedValue(packagesProtectionRuleQueryPayload());

        createComponent({
          packagesProtectionRuleQueryResolver,
        });

        await waitForPromises();

        expect(packagesProtectionRuleQueryResolver).toHaveBeenCalledTimes(1);

        await beforeFn();
        await findProtectionRuleForm().vm.$emit('submit');

        expect(findDrawer().props('open')).toBe(false);
        expect(packagesProtectionRuleQueryResolver).toHaveBeenCalledTimes(2);
        expect($toast.show).toHaveBeenCalledWith(toastMessage);
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
});

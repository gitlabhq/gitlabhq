import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlBadge, GlModal, GlSprintf, GlTable } from '@gitlab/ui';

import containerProtectionTagRuleEmptyRulesQueryPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/queries/get_container_protection_tag_rules.query.graphql.empty_rules.json';
import containerProtectionTagRuleNullProjectQueryPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/queries/get_container_protection_tag_rules.query.graphql.null_project.json';
import containerProtectionTagRuleQueryPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/queries/get_container_protection_tag_rules.query.graphql.json';
import deleteContainerProtectionTagRuleMutationPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/mutations/delete_container_protection_tag_rule.mutation.graphql.json';
import deleteContainerProtectionTagRuleMutationErrorPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/mutations/delete_container_protection_tag_rule.mutation.graphql.errors.json';

import createMockApollo from 'helpers/mock_apollo_helper';
import { getBinding } from 'helpers/vue_mock_directive';
import {
  mountExtended,
  shallowMountExtended,
  extendedWrapper,
} from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import ContainerProtectionTagRules from '~/packages_and_registries/settings/project/components/container_protection_tag_rules.vue';
import getContainerProtectionTagRulesQuery from '~/packages_and_registries/settings/project/graphql/queries/get_container_protection_tag_rules.query.graphql';
import deleteContainerProtectionTagRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/delete_container_protection_tag_rule.mutation.graphql';
import { MinimumAccessLevelOptions } from '~/packages_and_registries/settings/project/constants';

Vue.use(VueApollo);

describe('ContainerProtectionTagRules', () => {
  let apolloProvider;
  let wrapper;

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findDescription = () => wrapper.findByTestId('description');
  const findEmptyText = () => wrapper.findByTestId('empty-text');
  const findLoader = () => wrapper.findByTestId('loading-icon');
  const findTableLoader = () => wrapper.findByTestId('table-loading-icon');
  const findTableComponent = () => wrapper.findComponent(GlTable);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findModal = () => wrapper.findComponent(GlModal);

  const defaultProvidedValues = {
    projectPath: 'path',
  };

  const { nodes: tagRules } =
    containerProtectionTagRuleQueryPayload.data.project.containerProtectionTagRules;

  const $toast = { show: jest.fn() };

  const createComponent = ({
    mountFn = shallowMountExtended,
    provide = defaultProvidedValues,
    containerProtectionTagRuleQueryResolver = jest
      .fn()
      .mockResolvedValue(containerProtectionTagRuleQueryPayload),
    deleteContainerProtectionTagRuleMutationResolver = jest
      .fn()
      .mockResolvedValue(deleteContainerProtectionTagRuleMutationPayload),
  } = {}) => {
    const requestHandlers = [
      [getContainerProtectionTagRulesQuery, containerProtectionTagRuleQueryResolver],
      [deleteContainerProtectionTagRuleMutation, deleteContainerProtectionTagRuleMutationResolver],
    ];

    apolloProvider = createMockApollo(requestHandlers);
    wrapper = mountFn(ContainerProtectionTagRules, {
      apolloProvider,
      mocks: {
        $toast,
      },
      provide,
      stubs: {
        GlModal: true,
        GlSprintf,
      },
    });
  };

  describe('layout', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders card component with title', () => {
      expect(findCrudComponent().props('title')).toBe('Protected container image tags');
    });

    it('renders card component with description', () => {
      expect(findDescription().text()).toBe(
        'When a container image tag is protected, only certain user roles can create, update, and delete the protected tag, which helps to prevent unauthorized changes. You can add up to 5 protection rules per project.',
      );
    });

    it('shows loading icon', () => {
      expect(findLoader().exists()).toBe(true);
    });

    it('hides the table', () => {
      expect(findTableComponent().exists()).toBe(false);
    });

    it('hides count badge', () => {
      expect(findBadge().exists()).toBe(false);
    });

    it('calls graphql api query', () => {
      const containerProtectionTagRuleQueryResolver = jest
        .fn()
        .mockResolvedValue(containerProtectionTagRuleQueryPayload);
      createComponent({ containerProtectionTagRuleQueryResolver });

      expect(containerProtectionTagRuleQueryResolver).toHaveBeenCalledWith(
        expect.objectContaining({ projectPath: defaultProvidedValues.projectPath, first: 5 }),
      );
    });
  });

  describe('when data is loaded & contains tag protection rules', () => {
    const findTable = () =>
      extendedWrapper(wrapper.findByRole('table', { name: /protected container image tags/i }));
    const findTableBody = () => extendedWrapper(findTable().findAllByRole('rowgroup').at(1));
    const findTableRow = (i) => extendedWrapper(findTableBody().findAllByRole('row').at(i));
    const findTableRowCell = (i, j) => extendedWrapper(findTableRow(i).findAllByRole('cell').at(j));
    const findTableRowButtonDelete = (i) =>
      findTableRow(i).findByRole('button', { name: /delete/i });

    describe('layout', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('hides loading icon', () => {
        expect(findLoader().exists()).toBe(false);
      });

      it('shows count badge', () => {
        expect(findBadge().text()).toMatchInterpolatedText('1 of 5');
      });

      it('shows table', () => {
        expect(findTableComponent().attributes()).toMatchObject({
          'aria-label': 'Protected container image tags',
          stacked: 'md',
        });
        expect(findTableComponent().props('fields')).toStrictEqual([
          {
            key: 'tagNamePattern',
            label: 'Tag pattern',
            tdClass: '!gl-align-middle',
          },
          {
            key: 'minimumAccessLevelForPush',
            label: 'Minimum access level to push',
            tdClass: '!gl-align-middle',
          },
          {
            key: 'minimumAccessLevelForDelete',
            label: 'Minimum access level to delete',
            tdClass: '!gl-align-middle',
          },
          {
            key: 'rowActions',
            label: 'Actions',
            thAlignRight: true,
            tdClass: '!gl-align-middle gl-text-right',
          },
        ]);
      });
    });

    describe('shows table rows', () => {
      beforeEach(async () => {
        createComponent({
          mountFn: mountExtended,
        });

        await waitForPromises();
      });

      it('with container protection tag rules', () => {
        tagRules.forEach((protectionRule, i) => {
          expect(findTableRowCell(i, 0).text()).toBe(protectionRule.tagNamePattern);
          expect(findTableRowCell(i, 1).text()).toBe(
            MinimumAccessLevelOptions[protectionRule.minimumAccessLevelForPush],
          );
          expect(findTableRowCell(i, 2).text()).toBe(
            MinimumAccessLevelOptions[protectionRule.minimumAccessLevelForDelete],
          );
        });
      });

      describe('column "rowActions"', () => {
        describe('button "Delete"', () => {
          it('exists in table', () => {
            expect(findTableRowButtonDelete(0).exists()).toBe(true);
          });

          describe('when button is clicked', () => {
            it('renders the "delete container protection rule" confirmation modal', async () => {
              await findTableRowButtonDelete(0).trigger('click');

              const modalId = getBinding(findTableRowButtonDelete(0).element, 'gl-modal');

              expect(findModal().props('modal-id')).toBe(modalId);
              expect(findModal().props('title')).toBe('Delete protection rule');
              expect(findModal().text()).toBe(
                'Are you sure you want to delete the protected container tags rule v.+?',
              );
            });
          });
        });
      });
    });

    describe('modal "confirmation for delete action"', () => {
      const createComponentAndClickButtonDeleteInTableRow = async ({
        tableRowIndex = 0,
        deleteContainerProtectionTagRuleMutationResolver = jest
          .fn()
          .mockResolvedValue(deleteContainerProtectionTagRuleMutationPayload),
      } = {}) => {
        createComponent({
          deleteContainerProtectionTagRuleMutationResolver,
          mountFn: mountExtended,
        });

        await waitForPromises();

        findTableRowButtonDelete(tableRowIndex).trigger('click');
      };

      describe('when modal button "primary" clicked', () => {
        const clickOnModalPrimaryBtn = () => findModal().vm.$emit('primary');

        it('shows the loading icon when graphql mutation is executed', async () => {
          await createComponentAndClickButtonDeleteInTableRow();

          await clickOnModalPrimaryBtn();

          expect(findLoader().exists()).toBe(false);
          expect(findTableLoader().exists()).toBe(true);
        });

        it('sends graphql mutation', async () => {
          const deleteContainerProtectionTagRuleMutationResolver = jest
            .fn()
            .mockResolvedValue(deleteContainerProtectionTagRuleMutationPayload);

          await createComponentAndClickButtonDeleteInTableRow({
            deleteContainerProtectionTagRuleMutationResolver,
          });

          await clickOnModalPrimaryBtn();

          expect(deleteContainerProtectionTagRuleMutationResolver).toHaveBeenCalledTimes(1);
          expect(deleteContainerProtectionTagRuleMutationResolver).toHaveBeenCalledWith({
            input: { id: tagRules[0].id },
          });
        });

        it('handles erroneous graphql mutation', async () => {
          const alertErrorMessage = 'Client error message';
          const deleteContainerProtectionTagRuleMutationResolver = jest
            .fn()
            .mockRejectedValue(new Error(alertErrorMessage));

          await createComponentAndClickButtonDeleteInTableRow({
            deleteContainerProtectionTagRuleMutationResolver,
          });

          await clickOnModalPrimaryBtn();

          await waitForPromises();

          expect(findAlert().text()).toBe(alertErrorMessage);
        });

        it('handles graphql mutation with error response', async () => {
          const deleteContainerProtectionTagRuleMutationResolver = jest
            .fn()
            .mockResolvedValue(deleteContainerProtectionTagRuleMutationErrorPayload);

          await createComponentAndClickButtonDeleteInTableRow({
            deleteContainerProtectionTagRuleMutationResolver,
          });

          await clickOnModalPrimaryBtn();

          await waitForPromises();

          expect(findAlert().text()).toBe(
            "The resource that you are attempting to access does not exist or you don't have permission to perform this action",
          );
        });

        it('refetches protection rules after successful graphql mutation', async () => {
          const deleteContainerProtectionTagRuleMutationResolver = jest
            .fn()
            .mockResolvedValue(deleteContainerProtectionTagRuleMutationPayload);

          const containerProtectionTagRuleQueryResolver = jest
            .fn()
            .mockResolvedValue(containerProtectionTagRuleQueryPayload);

          createComponent({
            containerProtectionTagRuleQueryResolver,
            deleteContainerProtectionTagRuleMutationResolver,
            mountFn: mountExtended,
          });

          await waitForPromises();

          expect(containerProtectionTagRuleQueryResolver).toHaveBeenCalledTimes(1);

          await findTableRowButtonDelete(0).trigger('click');

          await clickOnModalPrimaryBtn();

          expect(findTableLoader().exists()).toBe(true);

          await waitForPromises();

          expect(containerProtectionTagRuleQueryResolver).toHaveBeenCalledTimes(2);
          expect(findTableLoader().exists()).toBe(false);
        });

        it('shows a toast with success message', async () => {
          await createComponentAndClickButtonDeleteInTableRow();

          await clickOnModalPrimaryBtn();

          await waitForPromises();

          expect($toast.show).toHaveBeenCalledWith('Container protection rule deleted.');
        });
      });
    });
  });

  describe.each([
    ['project does not contain any rules', containerProtectionTagRuleEmptyRulesQueryPayload],
    ['project is null', containerProtectionTagRuleNullProjectQueryPayload],
  ])('when data is loaded & %s', (_, payload) => {
    beforeEach(async () => {
      createComponent({
        containerProtectionTagRuleQueryResolver: jest.fn().mockResolvedValue(payload),
      });
      await waitForPromises();
    });

    it('hides loading icon', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('hides the table', () => {
      expect(findTableComponent().exists()).toBe(false);
    });

    it('hides count badge', () => {
      expect(findBadge().exists()).toBe(false);
    });

    it('shows empty text', () => {
      expect(findEmptyText().text()).toBe('No container image tags are protected.');
    });
  });

  describe('when data fails to load', () => {
    beforeEach(async () => {
      createComponent({
        containerProtectionTagRuleQueryResolver: jest.fn().mockRejectedValue(new Error('error')),
      });
      await waitForPromises();
    });

    it('hides loading icon', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('hides the table', () => {
      expect(findTableComponent().exists()).toBe(false);
    });

    it('hides count badge', () => {
      expect(findBadge().exists()).toBe(false);
    });

    it('shows alert', () => {
      expect(findAlert().props()).toMatchObject({
        variant: 'danger',
      });
      expect(findAlert().text()).toBe('error');
    });
  });
});

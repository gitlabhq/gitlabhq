import Vue from 'vue';
import VueApollo from 'vue-apollo';
import {
  GlAlert,
  GlBadge,
  GlDrawer,
  GlModal,
  GlSkeletonLoader,
  GlSprintf,
  GlTable,
} from '@gitlab/ui';

import containerProtectionTagRuleEmptyRulesQueryPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/queries/get_container_protection_tag_rules.query.graphql.empty_rules.json';
import containerProtectionTagRuleMaxRulesQueryPayload from 'test_fixtures/graphql/packages_and_registries/settings/project/graphql/queries/get_container_protection_tag_rules.query.graphql.max_rules.json';
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
import ContainerProtectionTagRuleForm from '~/packages_and_registries/settings/project/components/container_protection_tag_rule_form.vue';
import getContainerProtectionTagRulesQuery from '~/packages_and_registries/settings/project/graphql/queries/get_container_protection_tag_rules.query.graphql';
import deleteContainerProtectionTagRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/delete_container_protection_tag_rule.mutation.graphql';
import { MinimumAccessLevelText } from '~/packages_and_registries/settings/project/constants';

Vue.use(VueApollo);

describe('ContainerProtectionTagRules', () => {
  let apolloProvider;
  let wrapper;

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findDescription = () => wrapper.findByTestId('description');
  const findEmptyText = () => wrapper.findByTestId('empty-text');
  const findMaxRulesText = () => wrapper.findByTestId('max-rules');
  const findLoader = () => wrapper.findByTestId('loading-icon');
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findTableLoader = () => wrapper.findByTestId('table-loading-icon');
  const findTableComponent = () => wrapper.findComponent(GlTable);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findDrawerTitle = () => wrapper.findComponent(GlDrawer).find('h2');
  const findForm = () => wrapper.findComponent(ContainerProtectionTagRuleForm);
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
      expect(findCrudComponent().props('toggleText')).toBeNull();
    });

    it('renders card component with description', () => {
      expect(findDescription().text()).toBe(
        'When a container image tag is protected, only certain user roles can create, update, and delete the protected tag, which helps to prevent unauthorized changes. You can add up to 5 protection rules per project.',
      );
    });

    it('shows loading icon', () => {
      expect(findLoader().exists()).toBe(true);
    });

    it('shows skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('drawer is hidden', () => {
      expect(findDrawer().props('open')).toBe(false);
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
    const findTableRowButtonEdit = (i) => findTableRow(i).findByRole('button', { name: /edit/i });
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

      it('hides skeleton loader', () => {
        expect(findSkeletonLoader().exists()).toBe(false);
      });

      it('sets toggleText prop on CrudComponent', () => {
        expect(findCrudComponent().props('toggleText')).toBe('Add protection rule');
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
            MinimumAccessLevelText[protectionRule.minimumAccessLevelForPush],
          );
          expect(findTableRowCell(i, 2).text()).toBe(
            MinimumAccessLevelText[protectionRule.minimumAccessLevelForDelete],
          );
        });
      });

      describe('column "rowActions"', () => {
        describe.each`
          buttonName  | buttonFinder
          ${'Edit'}   | ${findTableRowButtonEdit}
          ${'Delete'} | ${findTableRowButtonDelete}
        `('button "$buttonName"', ({ buttonFinder }) => {
          it('exists in table', () => {
            expect(buttonFinder(0).exists()).toBe(true);
          });

          describe('when button is clicked', () => {
            beforeEach(async () => {
              await buttonFinder(0).trigger('click');
            });

            it('renders the "delete container protection rule" confirmation modal', () => {
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

    describe.each`
      description                                       | beforeFn                                            | title                     | toastMessage
      ${'when `Add protection rule` button is clicked'} | ${() => findCrudComponent().vm.$emit('showForm')}   | ${'Add protection rule'}  | ${'Container protection rule created.'}
      ${'when `Edit` button for a rule is clicked'}     | ${() => findTableRowButtonEdit(0).trigger('click')} | ${'Edit protection rule'} | ${'Container protection rule updated.'}
    `('$description', ({ beforeFn, title, toastMessage }) => {
      beforeEach(async () => {
        createComponent({
          mountFn: mountExtended,
        });

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
        expect(findForm().exists()).toBe(true);
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
          await findForm().vm.$emit('cancel');
        });

        it('closes drawer', () => {
          expect(findDrawer().props('open')).toBe(false);
        });
      });

      describe('when form emits `submit` event', () => {
        it('refetches protection rules after successful graphql mutation', async () => {
          const containerProtectionTagRuleQueryResolver = jest
            .fn()
            .mockResolvedValue(containerProtectionTagRuleQueryPayload);

          createComponent({
            containerProtectionTagRuleQueryResolver,
            mountFn: mountExtended,
          });

          await waitForPromises();

          expect(containerProtectionTagRuleQueryResolver).toHaveBeenCalledTimes(1);

          await beforeFn();
          await findForm().vm.$emit('submit');

          expect(findDrawer().props('open')).toBe(false);
          expect(containerProtectionTagRuleQueryResolver).toHaveBeenCalledTimes(2);
          expect($toast.show).toHaveBeenCalledWith(toastMessage);
        });
      });
    });
  });

  describe('when data is loaded & contains maximum number of tag protection rules', () => {
    beforeEach(async () => {
      createComponent({
        containerProtectionTagRuleQueryResolver: jest
          .fn()
          .mockResolvedValue(containerProtectionTagRuleMaxRulesQueryPayload),
      });
      await waitForPromises();
    });

    it('hides skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('sets toggleText prop on CrudComponent to null', () => {
      expect(findCrudComponent().props('toggleText')).toBeNull();
    });

    it('shows maximum number of rules reached text', () => {
      expect(findMaxRulesText().text()).toBe('Maximum number of rules reached.');
    });

    it('shows count badge', () => {
      expect(findBadge().text()).toMatchInterpolatedText('5 of 5');
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

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlBadge, GlLoadingIcon, GlSprintf, GlTableLite } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  mountExtended,
  shallowMountExtended,
  extendedWrapper,
} from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import ContainerProtectionTagRules, {
  MinimumAccessLevelOptions,
} from '~/packages_and_registries/settings/project/components/container_protection_tag_rules.vue';
import getContainerProtectionTagRulesQuery from '~/packages_and_registries/settings/project/graphql/queries/get_container_protection_tag_rules.query.graphql';
import { containerProtectionTagRuleQueryPayload } from '../mock_data';

Vue.use(VueApollo);

describe('ContainerProtectionTagRules', () => {
  let apolloProvider;
  let wrapper;

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findDescription = () => wrapper.findByTestId('description');
  const findEmptyText = () => wrapper.findByTestId('empty-text');
  const findLoader = () => wrapper.findComponent(GlLoadingIcon);
  const findTableComponent = () => wrapper.findComponent(GlTableLite);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findAlert = () => wrapper.findComponent(GlAlert);

  const defaultProvidedValues = {
    projectPath: 'path',
  };

  const createComponent = ({
    mountFn = shallowMountExtended,
    provide = defaultProvidedValues,
    containerProtectionTagRuleQueryResolver = jest
      .fn()
      .mockResolvedValue(containerProtectionTagRuleQueryPayload()),
  } = {}) => {
    const requestHandlers = [
      [getContainerProtectionTagRulesQuery, containerProtectionTagRuleQueryResolver],
    ];

    apolloProvider = createMockApollo(requestHandlers);
    wrapper = mountFn(ContainerProtectionTagRules, {
      apolloProvider,
      provide,
      stubs: {
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
        'When a container image tag is protected, only certain user roles can create, update, and delete the protected tag, which helps to prevent unauthorized changes. You can add upto 5 protection rules per project.',
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
        .mockResolvedValue(containerProtectionTagRuleQueryPayload());
      createComponent({ containerProtectionTagRuleQueryResolver });

      expect(containerProtectionTagRuleQueryResolver).toHaveBeenCalledWith(
        expect.objectContaining({ projectPath: defaultProvidedValues.projectPath, first: 5 }),
      );
    });
  });

  describe('when data is loaded & contains tag protection rules', () => {
    describe('layout', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('hides loading icon', () => {
        expect(findLoader().exists()).toBe(false);
      });

      it('shows count badge', () => {
        expect(findBadge().text()).toMatchInterpolatedText('5 of 5');
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
        ]);
      });
    });

    describe('shows table rows', () => {
      const findTable = () =>
        extendedWrapper(wrapper.findByRole('table', { name: /protected container image tags/i }));
      const findTableBody = () => extendedWrapper(findTable().findAllByRole('rowgroup').at(1));
      const findTableRow = (i) => extendedWrapper(findTableBody().findAllByRole('row').at(i));
      const findTableRowCell = (i, j) =>
        extendedWrapper(findTableRow(i).findAllByRole('cell').at(j));

      beforeEach(async () => {
        createComponent({
          mountFn: mountExtended,
        });

        await waitForPromises();
      });

      it('with container protection tag rules', () => {
        containerProtectionTagRuleQueryPayload().data.project.containerProtectionTagRules.nodes.forEach(
          (protectionRule, i) => {
            expect(findTableRowCell(i, 0).text()).toBe(protectionRule.tagNamePattern);
            expect(findTableRowCell(i, 1).text()).toBe(
              MinimumAccessLevelOptions[protectionRule.minimumAccessLevelForPush],
            );
            expect(findTableRowCell(i, 2).text()).toBe(
              MinimumAccessLevelOptions[protectionRule.minimumAccessLevelForDelete],
            );
          },
        );
      });
    });
  });

  describe('when data is loaded & is empty', () => {
    beforeEach(async () => {
      createComponent({
        containerProtectionTagRuleQueryResolver: jest
          .fn()
          .mockResolvedValue(containerProtectionTagRuleQueryPayload({ nodes: [] })),
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

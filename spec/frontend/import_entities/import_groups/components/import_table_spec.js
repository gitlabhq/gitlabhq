import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import ImportTableRow from '~/import_entities/import_groups/components/import_table_row.vue';
import ImportTable from '~/import_entities/import_groups/components/import_table.vue';
import setTargetNamespaceMutation from '~/import_entities/import_groups/graphql/mutations/set_target_namespace.mutation.graphql';
import setNewNameMutation from '~/import_entities/import_groups/graphql/mutations/set_new_name.mutation.graphql';
import importGroupMutation from '~/import_entities/import_groups/graphql/mutations/import_group.mutation.graphql';

import { STATUSES } from '~/import_entities/constants';

import { availableNamespacesFixture, generateFakeEntry } from '../graphql/fixtures';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('import table', () => {
  let wrapper;
  let apolloProvider;

  const createComponent = ({ bulkImportSourceGroups }) => {
    apolloProvider = createMockApollo([], {
      Query: {
        availableNamespaces: () => availableNamespacesFixture,
        bulkImportSourceGroups,
      },
      Mutation: {
        setTargetNamespace: jest.fn(),
        setNewName: jest.fn(),
        importGroup: jest.fn(),
      },
    });

    wrapper = shallowMount(ImportTable, {
      localVue,
      apolloProvider,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders loading icon while performing request', async () => {
    createComponent({
      bulkImportSourceGroups: () => new Promise(() => {}),
    });
    await waitForPromises();

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('does not renders loading icon when request is completed', async () => {
    createComponent({
      bulkImportSourceGroups: () => [],
    });
    await waitForPromises();

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
  });

  it('renders import row for each group in response', async () => {
    const FAKE_GROUPS = [
      generateFakeEntry({ id: 1, status: STATUSES.NONE }),
      generateFakeEntry({ id: 2, status: STATUSES.FINISHED }),
    ];
    createComponent({
      bulkImportSourceGroups: () => FAKE_GROUPS,
    });
    await waitForPromises();

    expect(wrapper.findAll(ImportTableRow)).toHaveLength(FAKE_GROUPS.length);
  });

  describe('converts row events to mutation invocations', () => {
    const FAKE_GROUP = generateFakeEntry({ id: 1, status: STATUSES.NONE });

    beforeEach(() => {
      createComponent({
        bulkImportSourceGroups: () => [FAKE_GROUP],
      });
      return waitForPromises();
    });

    it.each`
      event                        | payload            | mutation                      | variables
      ${'update-target-namespace'} | ${'new-namespace'} | ${setTargetNamespaceMutation} | ${{ sourceGroupId: FAKE_GROUP.id, targetNamespace: 'new-namespace' }}
      ${'update-new-name'}         | ${'new-name'}      | ${setNewNameMutation}         | ${{ sourceGroupId: FAKE_GROUP.id, newName: 'new-name' }}
      ${'import-group'}            | ${undefined}       | ${importGroupMutation}        | ${{ sourceGroupId: FAKE_GROUP.id }}
    `('correctly maps $event to mutation', async ({ event, payload, mutation, variables }) => {
      jest.spyOn(apolloProvider.defaultClient, 'mutate');
      wrapper.find(ImportTableRow).vm.$emit(event, payload);
      await waitForPromises();
      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith({
        mutation,
        variables,
      });
    });
  });
});

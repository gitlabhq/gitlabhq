import { nextTick } from 'vue';
import { GlDisclosureDropdownItem, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import projectWorkItemTypesQueryResponse from 'test_fixtures/graphql/work_items/project_work_item_types.query.graphql.json';
import groupWorkItemTypesQueryResponse from 'test_fixtures/graphql/work_items/group_work_item_types.query.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CreateWorkItem from '~/work_items/components/create_work_item.vue';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import groupWorkItemTypesQuery from '~/work_items/graphql/group_work_item_types.query.graphql';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';

const showToast = jest.fn();

describe('CreateWorkItemModal', () => {
  let wrapper;

  const findTrigger = () => wrapper.find('[data-testid="new-epic-button"]');
  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.findComponent(CreateWorkItem);

  const projectSingleWorkItemTypeQueryResponse = {
    data: {
      workspace: {
        ...projectWorkItemTypesQueryResponse.data.workspace,
        workItemTypes: {
          nodes: [projectWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes[0]],
        },
      },
    },
  };

  const groupSingleWorkItemQueryResponse = {
    data: {
      workspace: {
        ...groupWorkItemTypesQueryResponse.data.workspace,
        workItemTypes: {
          nodes: [groupWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes[0]],
        },
      },
    },
  };

  const workItemTypesQueryHandler = jest.fn().mockResolvedValue({
    data: projectSingleWorkItemTypeQueryResponse.data,
  });

  const groupWorkItemTypesQueryHandler = jest.fn().mockResolvedValue({
    data: groupSingleWorkItemQueryResponse.data,
  });

  const createComponent = (propsData = { workItemTypeName: 'issue' }) => {
    const apolloProvider = createMockApollo([
      [projectWorkItemTypesQuery, workItemTypesQueryHandler],
      [groupWorkItemTypesQuery, groupWorkItemTypesQueryHandler],
    ]);

    wrapper = shallowMount(CreateWorkItemModal, {
      propsData,
      apolloProvider,
      provide: {
        fullPath: 'full-path',
        isGroup: false,
      },
      mocks: {
        $toast: {
          show: showToast,
        },
      },
    });
  };

  it('passes workItemTypeName to CreateWorkItem', () => {
    createComponent();

    expect(findForm().props('workItemTypeName')).toBe('issue');
  });

  it('shows toast on workItemCreated', async () => {
    createComponent();

    await waitForPromises();
    findForm().vm.$emit('workItemCreated', { webUrl: '/' });

    expect(showToast).toHaveBeenCalledWith('Issue created', expect.any(Object));
  });

  describe('default trigger', () => {
    it('opens modal on trigger click', async () => {
      createComponent();

      await waitForPromises();

      findTrigger().vm.$emit('click');

      await nextTick();

      expect(findModal().props('visible')).toBe(true);
    });
  });

  describe('dropdown item trigger', () => {
    it('renders a dropdown item component', () => {
      createComponent({ asDropdownItem: true });

      expect(findDropdownItem().exists()).toBe(true);
    });
  });

  it('closes modal on cancel event from form', async () => {
    createComponent();

    await waitForPromises();

    await nextTick();

    findForm().vm.$emit('cancel');

    expect(findModal().props('visible')).toBe(false);
  });
});

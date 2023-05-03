import { nextTick } from 'vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemTree from '~/work_items/components/work_item_links/work_item_tree.vue';
import WorkItemChildrenWrapper from '~/work_items/components/work_item_links/work_item_children_wrapper.vue';
import WorkItemLinksForm from '~/work_items/components/work_item_links/work_item_links_form.vue';
import OkrActionsSplitButton from '~/work_items/components/work_item_links/okr_actions_split_button.vue';

import {
  FORM_TYPES,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
} from '~/work_items/constants';
import { childrenWorkItems } from '../../mock_data';

describe('WorkItemTree', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findByTestId('tree-empty');
  const findToggleFormSplitButton = () => wrapper.findComponent(OkrActionsSplitButton);
  const findForm = () => wrapper.findComponent(WorkItemLinksForm);
  const findWorkItemLinkChildrenWrapper = () => wrapper.findComponent(WorkItemChildrenWrapper);

  const createComponent = ({
    workItemType = 'Objective',
    parentWorkItemType = 'Objective',
    confidential = false,
    children = childrenWorkItems,
    canUpdate = true,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemTree, {
      propsData: {
        workItemType,
        parentWorkItemType,
        workItemId: 'gid://gitlab/WorkItem/515',
        confidential,
        children,
        projectPath: 'test/project',
        canUpdate,
      },
    });

    wrapper.vm.$refs.wrapper.show = jest.fn();
  };

  it('displays Add button', () => {
    createComponent();

    expect(findToggleFormSplitButton().exists()).toBe(true);
  });

  it('displays empty state if there are no children', () => {
    createComponent({ children: [] });

    expect(findEmptyState().exists()).toBe(true);
  });

  it('renders hierarchy widget children container', () => {
    createComponent();

    expect(findWorkItemLinkChildrenWrapper().exists()).toBe(true);
    expect(findWorkItemLinkChildrenWrapper().props().children).toHaveLength(4);
  });

  it('does not display form by default', () => {
    createComponent();

    expect(findForm().exists()).toBe(false);
  });

  it.each`
    option                   | event                        | formType             | childType
    ${'New objective'}       | ${'showCreateObjectiveForm'} | ${FORM_TYPES.create} | ${WORK_ITEM_TYPE_ENUM_OBJECTIVE}
    ${'Existing objective'}  | ${'showAddObjectiveForm'}    | ${FORM_TYPES.add}    | ${WORK_ITEM_TYPE_ENUM_OBJECTIVE}
    ${'New key result'}      | ${'showCreateKeyResultForm'} | ${FORM_TYPES.create} | ${WORK_ITEM_TYPE_ENUM_KEY_RESULT}
    ${'Existing key result'} | ${'showAddKeyResultForm'}    | ${FORM_TYPES.add}    | ${WORK_ITEM_TYPE_ENUM_KEY_RESULT}
  `(
    'when selecting $option from split button, renders the form passing $formType and $childType',
    async ({ event, formType, childType }) => {
      createComponent();

      findToggleFormSplitButton().vm.$emit(event);
      await nextTick();

      expect(findForm().exists()).toBe(true);
      expect(findForm().props()).toMatchObject({
        formType,
        childrenType: childType,
        parentWorkItemType: 'Objective',
        parentConfidential: false,
      });
    },
  );

  describe('when no permission to update', () => {
    beforeEach(() => {
      createComponent({
        canUpdate: false,
      });
    });

    it('does not display button to toggle Add form', () => {
      expect(findToggleFormSplitButton().exists()).toBe(false);
    });

    it('does not display link menu on children', () => {
      expect(findWorkItemLinkChildrenWrapper().props('canUpdate')).toBe(false);
    });
  });
});

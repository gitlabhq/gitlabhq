import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlToggle } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WidgetWrapper from '~/work_items/components/widget_wrapper.vue';
import WorkItemTree from '~/work_items/components/work_item_links/work_item_tree.vue';
import WorkItemChildrenWrapper from '~/work_items/components/work_item_links/work_item_children_wrapper.vue';
import WorkItemLinksForm from '~/work_items/components/work_item_links/work_item_links_form.vue';
import WorkItemActionsSplitButton from '~/work_items/components/work_item_links/work_item_actions_split_button.vue';
import getAllowedWorkItemChildTypes from '~/work_items//graphql/work_item_allowed_children.query.graphql';
import {
  FORM_TYPES,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
} from '~/work_items/constants';
import { childrenWorkItems, allowedChildrenTypesResponse } from '../../mock_data';

Vue.use(VueApollo);

describe('WorkItemTree', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findByTestId('tree-empty');
  const findToggleFormSplitButton = () => wrapper.findComponent(WorkItemActionsSplitButton);
  const findForm = () => wrapper.findComponent(WorkItemLinksForm);
  const findWidgetWrapper = () => wrapper.findComponent(WidgetWrapper);
  const findWorkItemLinkChildrenWrapper = () => wrapper.findComponent(WorkItemChildrenWrapper);
  const findShowLabelsToggle = () => wrapper.findComponent(GlToggle);

  const allowedChildrenTypesHandler = jest.fn().mockResolvedValue(allowedChildrenTypesResponse);

  const createComponent = ({
    workItemType = 'Objective',
    parentWorkItemType = 'Objective',
    confidential = false,
    children = childrenWorkItems,
    canUpdate = true,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemTree, {
      apolloProvider: createMockApollo([
        [getAllowedWorkItemChildTypes, allowedChildrenTypesHandler],
      ]),
      propsData: {
        fullPath: 'test/project',
        workItemType,
        parentWorkItemType,
        workItemId: 'gid://gitlab/WorkItem/515',
        confidential,
        children,
        canUpdate,
      },
      stubs: { WidgetWrapper },
    });
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

  it('shows an error message on error', async () => {
    const errorMessage = 'Some error';
    createComponent();

    findWorkItemLinkChildrenWrapper().vm.$emit('error', errorMessage);
    await nextTick();

    expect(findWidgetWrapper().props('error')).toBe(errorMessage);
  });

  it('fetches allowed children types for current work item', async () => {
    createComponent();
    await waitForPromises();

    expect(allowedChildrenTypesHandler).toHaveBeenCalled();
  });

  it.each`
    option                   | formType             | childType
    ${'New objective'}       | ${FORM_TYPES.create} | ${WORK_ITEM_TYPE_ENUM_OBJECTIVE}
    ${'Existing objective'}  | ${FORM_TYPES.add}    | ${WORK_ITEM_TYPE_ENUM_OBJECTIVE}
    ${'New key result'}      | ${FORM_TYPES.create} | ${WORK_ITEM_TYPE_ENUM_KEY_RESULT}
    ${'Existing key result'} | ${FORM_TYPES.add}    | ${WORK_ITEM_TYPE_ENUM_KEY_RESULT}
  `(
    'when triggering action $option, renders the form passing $formType and $childType',
    async ({ formType, childType }) => {
      createComponent();

      wrapper.vm.showAddForm(formType, childType);
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

  it('emits `addChild` event when form emits `addChild` event', async () => {
    createComponent();

    wrapper.vm.showAddForm(FORM_TYPES.create, WORK_ITEM_TYPE_ENUM_OBJECTIVE);
    await nextTick();
    findForm().vm.$emit('addChild');

    expect(wrapper.emitted('addChild')).toEqual([[]]);
  });

  it.each`
    toggleValue
    ${true}
    ${false}
  `(
    'passes showLabels as $toggleValue to child items when toggle is $toggleValue',
    async ({ toggleValue }) => {
      createComponent();

      findShowLabelsToggle().vm.$emit('change', toggleValue);

      await nextTick();

      expect(findWorkItemLinkChildrenWrapper().props('showLabels')).toBe(toggleValue);
    },
  );
});

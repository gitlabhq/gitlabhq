import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemTree from '~/work_items/components/work_item_links/work_item_tree.vue';
import WorkItemLinksForm from '~/work_items/components/work_item_links/work_item_links_form.vue';
import WorkItemLinkChild from '~/work_items/components/work_item_links/work_item_link_child.vue';
import OkrActionsSplitButton from '~/work_items/components/work_item_links/okr_actions_split_button.vue';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';

import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

import {
  FORM_TYPES,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
} from '~/work_items/constants';
import { childrenWorkItems, workItemByIidResponseFactory } from '../../mock_data';

describe('WorkItemTree', () => {
  let wrapper;

  const getWorkItemQueryHandler = jest.fn().mockResolvedValue(workItemByIidResponseFactory());

  const findEmptyState = () => wrapper.findByTestId('tree-empty');
  const findToggleFormSplitButton = () => wrapper.findComponent(OkrActionsSplitButton);
  const findForm = () => wrapper.findComponent(WorkItemLinksForm);
  const findWorkItemLinkChildItems = () => wrapper.findAllComponents(WorkItemLinkChild);

  Vue.use(VueApollo);

  const createComponent = ({
    workItemType = 'Objective',
    parentWorkItemType = 'Objective',
    confidential = false,
    children = childrenWorkItems,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemTree, {
      apolloProvider: createMockApollo([[workItemByIidQuery, getWorkItemQueryHandler]]),
      propsData: {
        workItemType,
        parentWorkItemType,
        workItemId: 'gid://gitlab/WorkItem/515',
        confidential,
        children,
        projectPath: 'test/project',
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

  it('renders all hierarchy widget children', () => {
    createComponent();

    const workItemLinkChildren = findWorkItemLinkChildItems();
    expect(workItemLinkChildren).toHaveLength(4);
    expect(workItemLinkChildren.at(0).props().childItem.confidential).toBe(
      childrenWorkItems[0].confidential,
    );
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

  it('remove event on child triggers `removeChild` event', () => {
    createComponent();
    const firstChild = findWorkItemLinkChildItems().at(0);

    firstChild.vm.$emit('removeChild', 'gid://gitlab/WorkItem/2');

    expect(wrapper.emitted('removeChild')).toEqual([['gid://gitlab/WorkItem/2']]);
  });

  it('emits `show-modal` on `click` event', () => {
    createComponent();
    const firstChild = findWorkItemLinkChildItems().at(0);
    const event = {
      childItem: 'gid://gitlab/WorkItem/2',
    };

    firstChild.vm.$emit('click', event);

    expect(wrapper.emitted('show-modal')).toEqual([[event, event.childItem]]);
  });

  it.each`
    description            | workItemType   | prefetch
    ${'prefetches'}        | ${'Issue'}     | ${true}
    ${'does not prefetch'} | ${'Objective'} | ${false}
  `(
    '$description work-item-link-child on mouseover when workItemType is "$workItemType"',
    async ({ workItemType, prefetch }) => {
      createComponent({ workItemType });
      const firstChild = findWorkItemLinkChildItems().at(0);
      firstChild.vm.$emit('mouseover', childrenWorkItems[0]);
      await nextTick();
      await waitForPromises();

      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);

      if (prefetch) {
        expect(getWorkItemQueryHandler).toHaveBeenCalled();
      } else {
        expect(getWorkItemQueryHandler).not.toHaveBeenCalled();
      }
    },
  );
});

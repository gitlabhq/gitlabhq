import { GlLabel, GlIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import WorkItemLinkChildMetadata from 'ee_else_ce/work_items/components/work_item_links/work_item_link_child_metadata.vue';

import { createAlert } from '~/alert';
import RichTimestampTooltip from '~/vue_shared/components/rich_timestamp_tooltip.vue';

import getWorkItemTreeQuery from '~/work_items/graphql/work_item_tree.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import WorkItemLinkChild from '~/work_items/components/work_item_links/work_item_link_child.vue';
import WorkItemLinksMenu from '~/work_items/components/work_item_links/work_item_links_menu.vue';
import WorkItemTreeChildren from '~/work_items/components/work_item_links/work_item_tree_children.vue';
import {
  WIDGET_TYPE_HIERARCHY,
  TASK_TYPE_NAME,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
} from '~/work_items/constants';

import {
  workItemTask,
  workItemObjectiveWithChild,
  workItemObjectiveNoMetadata,
  confidentialWorkItemTask,
  closedWorkItemTask,
  workItemHierarchyTreeResponse,
  workItemHierarchyTreeFailureResponse,
  workItemObjectiveMetadataWidgets,
  changeIndirectWorkItemParentMutationResponse,
  workItemUpdateFailureResponse,
} from '../../mock_data';

jest.mock('~/alert');

describe('WorkItemLinkChild', () => {
  const WORK_ITEM_ID = 'gid://gitlab/WorkItem/2';
  let wrapper;
  let getWorkItemTreeQueryHandler;
  let mutationChangeParentHandler;
  const { LABELS } = workItemObjectiveMetadataWidgets;
  const mockLabels = LABELS.labels.nodes;

  const $toast = {
    show: jest.fn(),
    hide: jest.fn(),
  };

  Vue.use(VueApollo);

  const createComponent = ({
    canUpdate = true,
    issuableGid = WORK_ITEM_ID,
    childItem = workItemTask,
    workItemType = TASK_TYPE_NAME,
    apolloProvider = null,
  } = {}) => {
    getWorkItemTreeQueryHandler = jest.fn().mockResolvedValue(workItemHierarchyTreeResponse);
    mutationChangeParentHandler = jest
      .fn()
      .mockResolvedValue(changeIndirectWorkItemParentMutationResponse);

    wrapper = shallowMountExtended(WorkItemLinkChild, {
      apolloProvider:
        apolloProvider ||
        createMockApollo([
          [getWorkItemTreeQuery, getWorkItemTreeQueryHandler],
          [updateWorkItemMutation, mutationChangeParentHandler],
        ]),
      provide: {
        fullPath: 'gitlab-org/gitlab-test',
      },
      propsData: {
        canUpdate,
        issuableGid,
        childItem,
        workItemType,
      },
      mocks: {
        $toast,
      },
    });
  };

  beforeEach(() => {
    createAlert.mockClear();
  });

  it.each`
    status      | childItem             | statusIconName    | statusIconColorClass   | rawTimestamp                   | tooltipContents
    ${'open'}   | ${workItemTask}       | ${'issue-open-m'} | ${'gl-text-green-500'} | ${workItemTask.createdAt}      | ${'Created'}
    ${'closed'} | ${closedWorkItemTask} | ${'issue-close'}  | ${'gl-text-blue-500'}  | ${closedWorkItemTask.closedAt} | ${'Closed'}
  `(
    'renders item status icon and tooltip when item status is `$status`',
    ({ childItem, statusIconName, statusIconColorClass, rawTimestamp, tooltipContents }) => {
      createComponent({ childItem });

      const statusIcon = wrapper.findByTestId('item-status-icon').findComponent(GlIcon);
      const statusTooltip = wrapper.findComponent(RichTimestampTooltip);

      expect(statusIcon.props('name')).toBe(statusIconName);
      expect(statusIcon.classes()).toContain(statusIconColorClass);
      expect(statusTooltip.props('rawTimestamp')).toBe(rawTimestamp);
      expect(statusTooltip.props('timestampTypeText')).toContain(tooltipContents);
    },
  );

  it('renders confidential icon when item is confidential', () => {
    createComponent({ childItem: confidentialWorkItemTask });

    const confidentialIcon = wrapper.findByTestId('confidential-icon');

    expect(confidentialIcon.props('name')).toBe('eye-slash');
    expect(confidentialIcon.attributes('title')).toBe('Confidential');
  });

  describe('item title', () => {
    let titleEl;

    beforeEach(() => {
      createComponent();

      titleEl = wrapper.findByTestId('item-title');
    });

    it('renders item title', () => {
      expect(titleEl.attributes('href')).toBe('/gitlab-org/gitlab-test/-/work_items/4');
      expect(titleEl.text()).toBe(workItemTask.title);
    });

    describe('renders item title correctly for relative instance', () => {
      beforeEach(() => {
        window.gon = { relative_url_root: '/test' };
        createComponent();
        titleEl = wrapper.findByTestId('item-title');
      });

      it('renders item title with correct href', () => {
        expect(titleEl.attributes('href')).toBe('/test/gitlab-org/gitlab-test/-/work_items/4');
      });

      it('renders item title with correct text', () => {
        expect(titleEl.text()).toBe(workItemTask.title);
      });
    });

    it.each`
      action                  | event          | emittedEvent
      ${'doing mouseover on'} | ${'mouseover'} | ${'mouseover'}
      ${'doing mouseout on'}  | ${'mouseout'}  | ${'mouseout'}
    `('$action item title emit `$emittedEvent` event', ({ event, emittedEvent }) => {
      titleEl.vm.$emit(event);

      expect(wrapper.emitted(emittedEvent)).toEqual([[]]);
    });

    it('emits click event with correct parameters on clicking title', () => {
      const eventObj = {
        preventDefault: jest.fn(),
      };
      titleEl.vm.$emit('click', eventObj);

      expect(wrapper.emitted('click')).toEqual([[eventObj]]);
    });
  });

  describe('item metadata', () => {
    const findMetadataComponent = () => wrapper.findComponent(WorkItemLinkChildMetadata);

    beforeEach(() => {
      createComponent({
        childItem: workItemObjectiveWithChild,
        workItemType: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
      });
    });

    it('renders item metadata component when item has metadata present', () => {
      const metadataEl = findMetadataComponent();
      expect(metadataEl.exists()).toBe(true);
      expect(metadataEl.props()).toMatchObject({
        metadataWidgets: workItemObjectiveMetadataWidgets,
      });
    });

    it('does not render item metadata component when item has no metadata present', () => {
      createComponent({
        childItem: workItemObjectiveNoMetadata,
        workItemType: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
      });

      expect(findMetadataComponent().exists()).toBe(false);
    });

    it('renders labels', () => {
      const labels = wrapper.findAllComponents(GlLabel);
      const mockLabel = mockLabels[0];

      expect(labels).toHaveLength(mockLabels.length);
      expect(labels.at(0).props()).toMatchObject({
        title: mockLabel.title,
        backgroundColor: mockLabel.color,
        description: mockLabel.description,
        scoped: false,
      });
      expect(labels.at(1).props('scoped')).toBe(true); // Second label is scoped
    });
  });

  describe('item menu', () => {
    let itemMenuEl;

    beforeEach(() => {
      createComponent();

      itemMenuEl = wrapper.findComponent(WorkItemLinksMenu);
    });

    it('renders work-item-links-menu', () => {
      expect(itemMenuEl.exists()).toBe(true);

      expect(itemMenuEl.attributes()).toMatchObject({
        'work-item-id': workItemTask.id,
        'parent-work-item-id': WORK_ITEM_ID,
      });
    });

    it('does not render work-item-links-menu when canUpdate is false', () => {
      createComponent({ canUpdate: false });

      expect(wrapper.findComponent(WorkItemLinksMenu).exists()).toBe(false);
    });

    it('removeChild event on menu triggers `click-remove-child` event', () => {
      itemMenuEl.vm.$emit('removeChild');

      expect(wrapper.emitted('removeChild')).toEqual([[workItemTask]]);
    });
  });

  describe('nested children', () => {
    const findExpandButton = () => wrapper.findByTestId('expand-child');
    const findTreeChildren = () => wrapper.findComponent(WorkItemTreeChildren);

    const getWidgetHierarchy = () =>
      workItemHierarchyTreeResponse.data.workItem.widgets.find(
        (widget) => widget.type === WIDGET_TYPE_HIERARCHY,
      );
    const getChildrenNodes = () => getWidgetHierarchy().children.nodes;
    const findFirstItem = () => getChildrenNodes()[0];

    beforeEach(() => {
      getWorkItemTreeQueryHandler.mockClear();
      createComponent({
        childItem: workItemObjectiveWithChild,
        workItemType: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
      });
    });

    it('displays expand button when item has children, children are not displayed by default', () => {
      expect(findExpandButton().exists()).toBe(true);
      expect(findTreeChildren().exists()).toBe(false);
    });

    it('fetches and displays children of item when clicking on expand button', async () => {
      await findExpandButton().vm.$emit('click');

      expect(findExpandButton().props('loading')).toBe(true);
      await waitForPromises();

      expect(getWorkItemTreeQueryHandler).toHaveBeenCalled();
      expect(findTreeChildren().exists()).toBe(true);

      const childrenNodes = getChildrenNodes();
      expect(findTreeChildren().props('children')).toEqual(childrenNodes);
    });

    it('does not fetch children if already fetched once while clicking expand button', async () => {
      findExpandButton().vm.$emit('click'); // Expand for the first time
      await waitForPromises();

      expect(findTreeChildren().exists()).toBe(true);

      await findExpandButton().vm.$emit('click'); // Collapse
      findExpandButton().vm.$emit('click'); // Expand again
      await waitForPromises();

      expect(getWorkItemTreeQueryHandler).toHaveBeenCalledTimes(1); // ensure children were fetched only once.
      expect(findTreeChildren().exists()).toBe(true);
    });

    it('calls createAlert when children fetch request fails on clicking expand button', async () => {
      const getWorkItemTreeQueryFailureHandler = jest
        .fn()
        .mockRejectedValue(workItemHierarchyTreeFailureResponse);
      const apolloProvider = createMockApollo([
        [getWorkItemTreeQuery, getWorkItemTreeQueryFailureHandler],
      ]);

      createComponent({
        childItem: workItemObjectiveWithChild,
        workItemType: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
        apolloProvider,
      });

      findExpandButton().vm.$emit('click');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: expect.any(Object),
        message: 'Something went wrong while fetching children.',
      });
    });

    it('click event on child emits `click` event', async () => {
      findExpandButton().vm.$emit('click');
      await waitForPromises();

      findTreeChildren().vm.$emit('click', 'event');

      expect(wrapper.emitted('click')).toEqual([['event']]);
    });

    it('shows toast on removing child item', async () => {
      findExpandButton().vm.$emit('click');
      await waitForPromises();

      findTreeChildren().vm.$emit('removeChild', findFirstItem());
      await waitForPromises();

      expect($toast.show).toHaveBeenCalledWith('Child removed', {
        action: { onClick: expect.any(Function), text: 'Undo' },
      });
    });

    it('renders correct number of children after the removal', async () => {
      findExpandButton().vm.$emit('click');
      await waitForPromises();

      const childrenNodes = getChildrenNodes();
      expect(findTreeChildren().props('children')).toEqual(childrenNodes);

      findTreeChildren().vm.$emit('removeChild', findFirstItem());
      await waitForPromises();

      expect(findTreeChildren().props('children')).toEqual([]);
    });

    it('calls correct mutation with correct variables', async () => {
      const firstItem = findFirstItem();

      findExpandButton().vm.$emit('click');
      await waitForPromises();

      findTreeChildren().vm.$emit('removeChild', firstItem);

      expect(mutationChangeParentHandler).toHaveBeenCalledWith({
        input: {
          id: firstItem.id,
          hierarchyWidget: {
            parentId: null,
          },
        },
      });
    });

    it('shows the alert when workItem update fails', async () => {
      mutationChangeParentHandler = jest.fn().mockRejectedValue(workItemUpdateFailureResponse);
      const apolloProvider = createMockApollo([
        [getWorkItemTreeQuery, getWorkItemTreeQueryHandler],
        [updateWorkItemMutation, mutationChangeParentHandler],
      ]);

      createComponent({
        childItem: workItemObjectiveWithChild,
        workItemType: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
        apolloProvider,
      });

      findExpandButton().vm.$emit('click');
      await waitForPromises();

      findTreeChildren().vm.$emit('removeChild', findFirstItem());
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: expect.any(Object),
        message: 'Something went wrong while removing child.',
      });
    });
  });
});

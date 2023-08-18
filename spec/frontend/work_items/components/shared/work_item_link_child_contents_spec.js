import { GlLabel, GlIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import WorkItemLinkChildMetadata from 'ee_else_ce/work_items/components/shared/work_item_link_child_metadata.vue';

import { createAlert } from '~/alert';
import RichTimestampTooltip from '~/vue_shared/components/rich_timestamp_tooltip.vue';

import WorkItemLinkChildContents from '~/work_items/components/shared/work_item_link_child_contents.vue';
import WorkItemLinksMenu from '~/work_items/components/shared/work_item_links_menu.vue';
import { TASK_TYPE_NAME, WORK_ITEM_TYPE_VALUE_OBJECTIVE } from '~/work_items/constants';

import {
  workItemTask,
  workItemObjectiveWithChild,
  workItemObjectiveNoMetadata,
  confidentialWorkItemTask,
  closedWorkItemTask,
  workItemObjectiveMetadataWidgets,
} from '../../mock_data';

jest.mock('~/alert');

describe('WorkItemLinkChildContents', () => {
  Vue.use(VueApollo);

  const WORK_ITEM_ID = 'gid://gitlab/WorkItem/2';
  let wrapper;
  const { LABELS } = workItemObjectiveMetadataWidgets;
  const mockLabels = LABELS.labels.nodes;
  const mockFullPath = 'gitlab-org/gitlab-test';

  const findStatusIconComponent = () =>
    wrapper.findByTestId('item-status-icon').findComponent(GlIcon);
  const findConfidentialIconComponent = () => wrapper.findByTestId('confidential-icon');
  const findTitleEl = () => wrapper.findByTestId('item-title');
  const findStatusTooltipComponent = () => wrapper.findComponent(RichTimestampTooltip);
  const findMetadataComponent = () => wrapper.findComponent(WorkItemLinkChildMetadata);
  const findAllLabels = () => wrapper.findAllComponents(GlLabel);
  const findRegularLabel = () => findAllLabels().at(0);
  const findScopedLabel = () => findAllLabels().at(1);
  const findLinksMenuComponent = () => wrapper.findComponent(WorkItemLinksMenu);

  const createComponent = ({
    canUpdate = true,
    parentWorkItemId = WORK_ITEM_ID,
    childItem = workItemTask,
    workItemType = TASK_TYPE_NAME,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinkChildContents, {
      propsData: {
        canUpdate,
        parentWorkItemId,
        childItem,
        workItemType,
        fullPath: mockFullPath,
        childPath: '/gitlab-org/gitlab-test/-/work_items/4',
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

      expect(findStatusIconComponent().props('name')).toBe(statusIconName);
      expect(findStatusIconComponent().classes()).toContain(statusIconColorClass);
      expect(findStatusTooltipComponent().props('rawTimestamp')).toBe(rawTimestamp);
      expect(findStatusTooltipComponent().props('timestampTypeText')).toContain(tooltipContents);
    },
  );

  it('renders confidential icon when item is confidential', () => {
    createComponent({ childItem: confidentialWorkItemTask });

    expect(findConfidentialIconComponent().props('name')).toBe('eye-slash');
    expect(findConfidentialIconComponent().attributes('title')).toBe('Confidential');
  });

  describe('item title', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders item title', () => {
      expect(findTitleEl().attributes('href')).toBe('/gitlab-org/gitlab-test/-/work_items/4');
      expect(findTitleEl().text()).toBe(workItemTask.title);
    });

    it.each`
      action            | event          | emittedEvent
      ${'on mouseover'} | ${'mouseover'} | ${'mouseover'}
      ${'on mouseout'}  | ${'mouseout'}  | ${'mouseout'}
    `('$action item title emit `$emittedEvent` event', ({ event, emittedEvent }) => {
      findTitleEl().vm.$emit(event);

      expect(wrapper.emitted(emittedEvent)).toEqual([[]]);
    });

    it('emits click event with correct parameters on clicking title', () => {
      const eventObj = {
        preventDefault: jest.fn(),
      };
      findTitleEl().vm.$emit('click', eventObj);

      expect(wrapper.emitted('click')).toEqual([[eventObj]]);
    });
  });

  describe('item metadata', () => {
    beforeEach(() => {
      createComponent({
        childItem: workItemObjectiveWithChild,
        workItemType: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
      });
    });

    it('renders item metadata component when item has metadata present', () => {
      expect(findMetadataComponent().props()).toMatchObject({
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
      const mockLabel = mockLabels[0];

      expect(findAllLabels()).toHaveLength(mockLabels.length);
      expect(findRegularLabel().props()).toMatchObject({
        title: mockLabel.title,
        backgroundColor: mockLabel.color,
        description: mockLabel.description,
        scoped: false,
      });
      expect(findScopedLabel().props('scoped')).toBe(true); // Second label is scoped
    });
  });

  describe('item menu', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders work-item-links-menu', () => {
      expect(findLinksMenuComponent().exists()).toBe(true);
    });

    it('does not render work-item-links-menu when canUpdate is false', () => {
      createComponent({ canUpdate: false });

      expect(findLinksMenuComponent().exists()).toBe(false);
    });

    it('removeChild event on menu triggers `click-remove-child` event', () => {
      findLinksMenuComponent().vm.$emit('removeChild');

      expect(wrapper.emitted('removeChild')).toEqual([[workItemTask]]);
    });
  });
});

import { GlLabel, GlIcon, GlLink, GlButton, GlAvatarsInline } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import WorkItemLinkChildMetadata from 'ee_else_ce/work_items/components/shared/work_item_link_child_metadata.vue';

import { createAlert } from '~/alert';
import RichTimestampTooltip from '~/vue_shared/components/rich_timestamp_tooltip.vue';

import WorkItemLinkChildContents from '~/work_items/components/shared/work_item_link_child_contents.vue';
import { WORK_ITEM_TYPE_VALUE_OBJECTIVE } from '~/work_items/constants';

import {
  workItemTask,
  workItemObjectiveWithChild,
  confidentialWorkItemTask,
  closedWorkItemTask,
  workItemObjectiveMetadataWidgets,
} from '../../mock_data';

jest.mock('~/alert');

describe('WorkItemLinkChildContents', () => {
  Vue.use(VueApollo);

  let wrapper;
  const { LABELS, ASSIGNEES } = workItemObjectiveMetadataWidgets;
  const mockAssignees = ASSIGNEES.assignees.nodes;
  const mockLabels = LABELS.labels.nodes;

  const findStatusIconComponent = () =>
    wrapper.findByTestId('item-status-icon').findComponent(GlIcon);
  const findConfidentialIconComponent = () => wrapper.findByTestId('confidential-icon');
  const findTitleEl = () => wrapper.findComponent(GlLink);
  const findStatusTooltipComponent = () => wrapper.findComponent(RichTimestampTooltip);
  const findMetadataComponent = () => wrapper.findComponent(WorkItemLinkChildMetadata);
  const findAllLabels = () => wrapper.findAllComponents(GlLabel);
  const findRegularLabel = () => findAllLabels().at(0);
  const findScopedLabel = () => findAllLabels().at(1);
  const findRemoveButton = () => wrapper.findComponent(GlButton);

  const createComponent = ({
    canUpdate = true,
    childItem = workItemTask,
    showLabels = true,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinkChildContents, {
      propsData: {
        canUpdate,
        childItem,
        showLabels,
        workItemFullPath: 'test-project-path',
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

  it('renders avatars for assignees', () => {
    createComponent();

    const avatars = wrapper.findComponent(GlAvatarsInline);

    expect(avatars.exists()).toBe(true);
    expect(avatars.props()).toMatchObject({
      avatars: mockAssignees,
      collapsed: true,
      maxVisible: 2,
      avatarSize: 16,
      badgeTooltipProp: 'name',
      badgeSrOnlyText: '',
    });
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
    it('renders item metadata component when item has metadata present', () => {
      createComponent({
        childItem: workItemObjectiveWithChild,
        workItemType: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
      });

      expect(findMetadataComponent().props()).toMatchObject({
        iid: '12',
        reference: '#12',
        metadataWidgets: workItemObjectiveMetadataWidgets,
      });
    });
  });

  describe('item menu', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders remove button', () => {
      expect(findRemoveButton().exists()).toBe(true);
    });

    it('does not render work-item-links-menu when canUpdate is false', () => {
      createComponent({ canUpdate: false });

      expect(findRemoveButton().exists()).toBe(false);
    });

    it('removeChild event on menu triggers `click-remove-child` event', () => {
      findRemoveButton().vm.$emit('click');

      expect(wrapper.emitted('removeChild')).toEqual([[workItemTask]]);
    });
  });

  describe('item labels', () => {
    it('renders normal and scoped label', () => {
      createComponent({ childItem: workItemObjectiveWithChild });

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

    it.each`
      expectedAssertion           | showLabels
      ${'does not render labels'} | ${true}
      ${'renders label'}          | ${false}
    `('$expectedAssertion when showLabels is $showLabels', ({ showLabels }) => {
      createComponent({ showLabels, childItem: workItemObjectiveWithChild });

      expect(findAllLabels().exists()).toBe(showLabels);
    });
  });
});

import { GlLabel, GlLink, GlButton, GlAvatarsInline } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import WorkItemLinkChildMetadata from 'ee_else_ce/work_items/components/shared/work_item_link_child_metadata.vue';

import { createAlert } from '~/alert';
import RichTimestampTooltip from '~/work_items/components/rich_timestamp_tooltip.vue';
import WorkItemStateBadge from '~/work_items/components/work_item_state_badge.vue';
import WorkItemLinkChildContents from '~/work_items/components/shared/work_item_link_child_contents.vue';
import { WORK_ITEM_TYPE_VALUE_OBJECTIVE } from '~/work_items/constants';
import WorkItemRelationshipIcons from '~/work_items/components/shared/work_item_relationship_icons.vue';

import {
  workItemTask,
  workItemEpic,
  workItemObjectiveWithChild,
  confidentialWorkItemTask,
  closedWorkItemTask,
  otherNamespaceChild,
  workItemObjectiveMetadataWidgets,
  workItemObjectiveWithoutChild,
} from '../../mock_data';

jest.mock('~/alert');

describe('WorkItemLinkChildContents', () => {
  Vue.use(VueApollo);

  let wrapper;
  const { LABELS, ASSIGNEES } = workItemObjectiveMetadataWidgets;
  const mockAssignees = ASSIGNEES.assignees.nodes;
  const mockLabels = LABELS.labels.nodes;

  const mockRouterPush = jest.fn();

  const findLinkChild = () => wrapper.findByTestId('links-child');
  const findStatusBadgeComponent = () =>
    wrapper.findByTestId('item-status-icon').findComponent(WorkItemStateBadge);
  const findConfidentialIconComponent = () => wrapper.findByTestId('confidential-icon');
  const findTitleEl = () => wrapper.findComponent(GlLink);
  const findStatusTooltipComponent = () => wrapper.findComponent(RichTimestampTooltip);
  const findMetadataComponent = () => wrapper.findComponent(WorkItemLinkChildMetadata);
  const findAllLabels = () => wrapper.findAllComponents(GlLabel);
  const findRegularLabel = () => findAllLabels().at(0);
  const findScopedLabel = () => findAllLabels().at(1);
  const findRemoveButton = () => wrapper.findComponent(GlButton);
  const findRelationshipIconsComponent = () => wrapper.findComponent(WorkItemRelationshipIcons);

  const createComponent = ({
    canUpdate = true,
    childItem = workItemTask,
    showLabels = true,
    workItemFullPath = 'test-project-path',
    isGroup = false,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinkChildContents, {
      propsData: {
        canUpdate,
        childItem,
        showLabels,
        workItemFullPath,
      },
      provide: {
        isGroup,
      },
      mocks: {
        $router: {
          push: mockRouterPush,
        },
      },
    });
  };

  beforeEach(() => {
    createAlert.mockClear();
  });

  it.each`
    status      | childItem             | workItemState | rawTimestamp                   | tooltipContents
    ${'open'}   | ${workItemTask}       | ${'OPEN'}     | ${workItemTask.createdAt}      | ${'Created'}
    ${'closed'} | ${closedWorkItemTask} | ${'CLOSED'}   | ${closedWorkItemTask.closedAt} | ${'Closed'}
  `(
    'renders item status icon and tooltip when item status is `$status`',
    ({ childItem, workItemState, rawTimestamp, tooltipContents }) => {
      createComponent({ childItem });

      expect(findStatusBadgeComponent().props('workItemState')).toBe(workItemState);
      expect(findStatusTooltipComponent().props('rawTimestamp')).toBe(rawTimestamp);
      expect(findStatusTooltipComponent().props('timestampTypeText')).toContain(tooltipContents);
    },
  );

  it('renders confidential icon when item is confidential', () => {
    createComponent({ childItem: confidentialWorkItemTask });

    expect(findConfidentialIconComponent().props('name')).toBe('eye-slash');
    expect(findConfidentialIconComponent().attributes('title')).toBe('Confidential');
  });

  it('emits click event with correct parameters on clicking child', () => {
    createComponent();
    findLinkChild().trigger('click');

    expect(wrapper.emitted('click')).toHaveLength(1);
    expect(mockRouterPush).not.toHaveBeenCalled();
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

  it('renders link with unique id', () => {
    createComponent();

    expect(findTitleEl().attributes().id).toBe(
      `listItem-${workItemTask.namespace.fullPath}/${getIdFromGraphQLId(workItemTask.id)}`,
    );
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

    describe('when the linked item can be navigated to via Vue Router', () => {
      beforeEach(() => {
        createComponent({
          childItem: workItemEpic,
          isGroup: true,
          workItemFullPath: 'gitlab-org/gitlab-test',
        });

        findLinkChild().trigger('click');
      });

      it('pushes a new router state', () => {
        expect(mockRouterPush).toHaveBeenCalled();
      });

      it('does not emit a click event', () => {
        expect(wrapper.emitted('click')).not.toBeDefined();
      });
    });
  });

  describe('item metadata', () => {
    it('renders item metadata component when item has metadata present', () => {
      createComponent({
        childItem: workItemObjectiveWithoutChild,
        workItemType: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
      });

      expect(findMetadataComponent().props()).toMatchObject({
        iid: '12',
        reference: '#12',
        metadataWidgets: workItemObjectiveMetadataWidgets,
      });
    });
    it('renders full path when not in the same namespace', () => {
      createComponent({
        childItem: otherNamespaceChild,
      });

      expect(findMetadataComponent().props()).toMatchObject({
        iid: '24',
        reference: 'test-project-path/other#24',
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

    it('renders relationship icons', () => {
      expect(findRelationshipIconsComponent().exists()).toBe(true);
    });

    it('does not render relationship icons when item is closed', () => {
      createComponent({ childItem: closedWorkItemTask });

      expect(findRelationshipIconsComponent().exists()).toBe(false);
    });

    it('does not render work-item-links-menu when canUpdate is false', () => {
      createComponent({ canUpdate: false });

      expect(findRemoveButton().exists()).toBe(false);
    });

    it('removeChild event on menu triggers `click-remove-child` event', () => {
      findRemoveButton().vm.$emit('click', { stopPropagation: jest.fn() });

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

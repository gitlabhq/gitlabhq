import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { STATE_OPEN, STATE_CLOSED } from '~/work_items/constants';
import { issueType, taskType, workItemResponseFactory } from 'ee_else_ce_jest/work_items/mock_data';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import ArchivedBadge from '~/issuable/components/archived_badge.vue';
import WorkItemStickyHeader from '~/work_items/components/work_item_sticky_header.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import WorkItemStateBadge from '~/work_items/components/work_item_state_badge.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';

describe('WorkItemStickyHeader', () => {
  let wrapper;

  const createComponent = ({
    confidential = false,
    hidden = false,
    imported = false,
    discussionLocked = false,
    canUpdate = true,
    features = {},
    movedToWorkItemUrl = null,
    duplicatedToWorkItemUrl = null,
    promotedToEpicUrl = null,
    slots = {},
    isDrawer = false,
    archived = false,
    workItemState = STATE_OPEN,
    workItemType = taskType,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemStickyHeader, {
      propsData: {
        workItem: workItemResponseFactory({
          canUpdate,
          confidential,
          discussionLocked,
          hidden,
          imported,
          movedToWorkItemUrl,
          duplicatedToWorkItemUrl,
          promotedToEpicUrl,
          workItemType,
          state: workItemState,
        }).data.workItem,
        updateInProgress: false,
        workItemState,
        isDrawer,
        archived,
      },
      provide: {
        glFeatures: {
          ...features,
        },
      },
      slots,
    });
  };

  const findConfidentialityBadge = () => wrapper.findComponent(ConfidentialityBadge);
  const findHiddenBadge = () => wrapper.findComponent(HiddenBadge);
  const findImportedBadge = () => wrapper.findComponent(ImportedBadge);
  const findLockedBadge = () => wrapper.findComponent(LockedBadge);
  const findArchivedBadge = () => wrapper.findComponent(ArchivedBadge);
  const findWorkItemStateBadge = () => wrapper.findComponent(WorkItemStateBadge);
  const findWorkItemTitle = () => wrapper.findComponent(GlLink);
  const findWorkItemTypeIcon = () => wrapper.findComponent(WorkItemTypeIcon);

  it('renders title', () => {
    createComponent();

    expect(findWorkItemTitle().exists()).toBe(true);
  });

  it('has title with the link to the top', () => {
    createComponent();
    expect(findWorkItemTitle().attributes('href')).toBe('#top');
  });

  describe('WorkItemStateBadge', () => {
    it('renders when work item is closed', () => {
      createComponent({ workItemState: STATE_CLOSED });

      expect(findWorkItemStateBadge().exists()).toBe(true);
    });

    it('does not render when work item is open', () => {
      createComponent({ workItemState: STATE_OPEN });

      expect(findWorkItemStateBadge().exists()).toBe(false);
    });

    it('passes URL props correctly when they exist and work item is closed', async () => {
      // We'll never populate all of these attributes because
      // a work item can only have one closed reason.
      // For simplicity we're passing all of them to easily assert
      // that the props are passed correctly.
      const workItemAttributes = {
        movedToWorkItemUrl: 'http://example.com/moved',
        duplicatedToWorkItemUrl: 'http://example.com/duplicated',
        promotedToEpicUrl: 'http://example.com/epic',
        workItemState: STATE_CLOSED,
      };

      await createComponent(workItemAttributes);

      const stateBadgeProps = findWorkItemStateBadge().props();
      Object.entries(workItemAttributes).forEach(([prop, url]) => {
        expect(stateBadgeProps[prop]).toBe(url);
      });
    });
  });

  describe('work item type icon', () => {
    it('renders the work item type icon', () => {
      createComponent({ workItemType: taskType });

      expect(findWorkItemTypeIcon().exists()).toBe(true);
    });

    it('passes correct work item type and showTooltipOnHover props to the icon component', () => {
      createComponent({ workItemType: issueType });

      expect(findWorkItemTypeIcon().props('workItemType')).toBe('Issue');
      expect(findWorkItemTypeIcon().props('showTooltipOnHover')).toBe(true);
    });
  });

  describe('confidential badge', () => {
    describe('when not confidential', () => {
      beforeEach(() => {
        createComponent({ confidential: false });
      });

      it('does not render', () => {
        expect(findConfidentialityBadge().exists()).toBe(false);
      });
    });

    describe('when confidential', () => {
      beforeEach(() => {
        createComponent({ confidential: true });
      });

      it('renders', () => {
        expect(findConfidentialityBadge().exists()).toBe(true);
      });
    });
  });

  describe('locked badge', () => {
    describe('when discussion is not locked', () => {
      beforeEach(() => {
        createComponent({ discussionLocked: false });
      });

      it('does not render', () => {
        expect(findLockedBadge().exists()).toBe(false);
      });
    });

    describe('when discussion is locked', () => {
      beforeEach(() => {
        createComponent({ discussionLocked: true });
      });

      it('renders', () => {
        expect(findLockedBadge().exists()).toBe(true);
      });
    });
  });

  describe('archived and status badge', () => {
    describe.each`
      archived | workItemState   | archivedBadgeExists | stateBadgeExists | description
      ${false} | ${undefined}    | ${false}            | ${false}         | ${'when not archived'}
      ${true}  | ${undefined}    | ${true}             | ${false}         | ${'when archived'}
      ${true}  | ${STATE_OPEN}   | ${true}             | ${false}         | ${'when archived and work item is open'}
      ${true}  | ${STATE_CLOSED} | ${true}             | ${false}         | ${'when archived and work item is closed'}
      ${false} | ${STATE_OPEN}   | ${false}            | ${false}         | ${'when not archived and work item is open'}
      ${false} | ${STATE_CLOSED} | ${false}            | ${true}          | ${'when not archived and work item is closed'}
    `('$description', ({ archived, workItemState, archivedBadgeExists, stateBadgeExists }) => {
      beforeEach(() => {
        createComponent({ archived, workItemState });
      });

      it(`${archivedBadgeExists ? 'renders' : 'does not render'} archived badge`, () => {
        expect(findArchivedBadge().exists()).toBe(archivedBadgeExists);
      });

      it(`${stateBadgeExists ? 'renders' : 'does not render'} state badge`, () => {
        expect(findWorkItemStateBadge().exists()).toBe(stateBadgeExists);
      });
    });

    describe('when archived', () => {
      beforeEach(() => {
        createComponent({ archived: true, workItemType: issueType });
      });

      it('passes correct issuable type to archived badge', () => {
        expect(findArchivedBadge().props('issuableType')).toBe('Issue');
      });
    });
  });

  describe('hidden badge', () => {
    it('renders when the work item is hidden', () => {
      createComponent({ hidden: true });

      expect(findHiddenBadge().exists()).toBe(true);
    });

    it('does not render when the work item is not hidden', () => {
      createComponent({ hidden: false });

      expect(findHiddenBadge().exists()).toBe(false);
    });
  });

  describe('imported badge', () => {
    it('renders when the work item is imported', () => {
      createComponent({ imported: true });

      expect(findImportedBadge().exists()).toBe(true);
    });

    it('does not render when the work item is not imported', () => {
      createComponent({ imported: false });

      expect(findImportedBadge().exists()).toBe(false);
    });
  });
});

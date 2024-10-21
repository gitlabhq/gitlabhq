import { GlDisclosureDropdownItem, GlDisclosureDropdown } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import moreActionsDropdown from '~/milestones/components/more_actions_dropdown.vue';
import DeleteMilestoneModal from '~/milestones/components/delete_milestone_modal.vue';
import PromoteMilestoneModal from '~/milestones/components/promote_milestone_modal.vue';

describe('moreActionsDropdown', () => {
  let wrapper;
  const defaultProvide = {
    id: 1,
    title: 'Milestone 1',
    isActive: true,
    showDelete: true,
    milestoneUrl: '/milestone-url',
    editUrl: '/edit-url',
    closeUrl: '/close-url',
    reopenUrl: '/reopen-url',
    promoteUrl: '/promote-url',
    groupName: 'test-group',
    issueCount: 1,
    mergeRequestCount: 2,
    isDetailPage: false,
    size: 'medium',
  };

  const createComponent = ({ provideData = {}, propsData = {} } = {}) => {
    wrapper = shallowMountExtended(moreActionsDropdown, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      provide: {
        ...defaultProvide,
        ...provideData,
      },
      propsData,
      stubs: {
        GlDisclosureDropdownItem,
        DeleteMilestoneModal,
        PromoteMilestoneModal,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const showDropdown = () => {
    findDropdown().vm.$emit('show');
  };
  const findDropdownTooltip = () => getBinding(findDropdown().element, 'gl-tooltip');
  const findEditItem = () => wrapper.findByTestId('milestone-edit-item');
  const findPromoteItem = () => wrapper.findByTestId('milestone-promote-item');
  const findPromoteMilestoneModal = () => wrapper.findComponent(PromoteMilestoneModal);
  const findCloseItem = () => wrapper.findByTestId('milestone-close-item');
  const findReopenItem = () => wrapper.findByTestId('milestone-reopen-item');
  const findDeleteItem = () => wrapper.findByTestId('milestone-delete-item');
  const findMilestoneIdItem = () => wrapper.findByTestId('copy-milestone-id');
  const findDeleteMilestoneModal = () => wrapper.findComponent(DeleteMilestoneModal);

  describe('dropdown group', () => {
    it('renders tooltip', () => {
      createComponent();

      expect(findDropdownTooltip().value).toBe('Milestone actions');
    });
  });

  describe('edit item', () => {
    it('renders with correct value if `editUrl` is set', () => {
      const provideData = {
        editUrl: '/my-edit-url',
      };

      createComponent({
        provideData,
      });

      expect(findEditItem().attributes('href')).toBe(provideData.editUrl);
    });

    it('does not render if `editUrl` is false', () => {
      createComponent({
        provideData: {
          editUrl: '',
        },
      });

      expect(findEditItem().exists()).toBe(false);
    });
  });

  describe('promote item', () => {
    const provideData = {
      promoteUrl: '/my-promote-url',
      groupName: 'promote-group',
      title: 'Milestone to promote',
    };

    it('renders with correct values if `promoteUrl` is set', () => {
      createComponent({
        provideData,
      });

      expect(findPromoteItem().exists()).toBe(true);
      expect(findPromoteMilestoneModal().props()).toMatchObject({
        visible: false,
        milestoneTitle: provideData.title,
        promoteUrl: provideData.promoteUrl,
        groupName: provideData.groupName,
      });
    });

    it('click on promote opens confirm modal with correct props', async () => {
      createComponent({
        provideData,
      });

      expect(findPromoteMilestoneModal().props('visible')).toBe(false);

      findPromoteItem().trigger('click');
      await nextTick();

      expect(findPromoteMilestoneModal().props()).toMatchObject({
        visible: true,
        milestoneTitle: provideData.title,
        promoteUrl: provideData.promoteUrl,
        groupName: provideData.groupName,
      });
    });

    it('does not render if `promoteUrl` is false', () => {
      createComponent({
        provideData: {
          promoteUrl: '',
        },
      });

      expect(findPromoteItem().exists()).toBe(false);
    });
  });

  describe('close item', () => {
    it('renders with correct values if `isActive` is set', () => {
      const provideData = {
        isActive: true,
        closeUrl: '/my-close-url',
      };

      createComponent({
        provideData,
      });

      expect(findCloseItem().exists()).toBe(true);
      expect(findReopenItem().exists()).toBe(false);
      expect(findCloseItem().attributes('href')).toBe(provideData.closeUrl);
    });

    it('does not render if `isActive` is false', () => {
      createComponent({
        provideData: {
          isActive: false,
        },
      });

      expect(findCloseItem().exists()).toBe(false);
      expect(findReopenItem().exists()).toBe(true);
    });

    it('has correct class if `isDetailPage` is true', () => {
      createComponent({
        provideData: {
          isDetailPage: true,
        },
      });

      expect(findCloseItem().attributes('class')).toContain('sm:!gl-hidden');
    });
  });

  describe('reopen item', () => {
    it('renders with correct values if `isActive` is set', () => {
      const provideData = {
        isActive: false,
        reopenUrl: '/my-reopen-url',
      };

      createComponent({
        provideData,
      });

      expect(findReopenItem().exists()).toBe(true);
      expect(findCloseItem().exists()).toBe(false);
      expect(findReopenItem().attributes('href')).toBe(provideData.reopenUrl);
    });

    it('does not render if `isActive` is false', () => {
      createComponent({
        provideData: {
          isActive: true,
        },
      });

      expect(findReopenItem().exists()).toBe(false);
      expect(findCloseItem().exists()).toBe(true);
    });

    it('has correct class if `isDetailPage` is true', () => {
      createComponent({
        provideData: {
          isActive: false,
          isDetailPage: true,
        },
      });

      expect(findReopenItem().attributes('class')).toContain('sm:!gl-hidden');
    });
  });

  describe('delete item', () => {
    const provideData = {
      issueCount: 1,
      mergeRequestCount: 2,
      milestoneId: 1,
      milestoneTitle: 'Milestone 1',
      milestoneUrl: '/milestone-url',
    };

    it('renders with correct values', () => {
      createComponent();

      expect(findDeleteItem().exists()).toBe(true);
      expect(findDeleteMilestoneModal().props()).toMatchObject({
        visible: false,
        issueCount: provideData.issueCount,
        mergeRequestCount: provideData.mergeRequestCount,
        milestoneId: provideData.milestoneId,
        milestoneTitle: provideData.milestoneTitle,
        milestoneUrl: provideData.milestoneUrl,
      });
    });

    it('click on delete opens confirm modal with correct props', async () => {
      createComponent();

      expect(findDeleteMilestoneModal().props('visible')).toBe(false);

      findDeleteItem().trigger('click');
      await nextTick();

      expect(findDeleteMilestoneModal().props()).toMatchObject({
        visible: true,
        issueCount: provideData.issueCount,
        mergeRequestCount: provideData.mergeRequestCount,
        milestoneId: provideData.milestoneId,
        milestoneTitle: provideData.milestoneTitle,
        milestoneUrl: provideData.milestoneUrl,
      });
    });
  });

  describe('copy milestone id item', () => {
    it('renders copy milestone id with correct id', () => {
      createComponent({
        provideData: {
          id: 22,
        },
      });

      showDropdown();

      expect(findMilestoneIdItem().text()).toBe('Copy milestone ID: 22');
    });
  });
});

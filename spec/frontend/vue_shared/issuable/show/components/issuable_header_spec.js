import { GlBadge, GlButton, GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import { STATUS_CLOSED, STATUS_OPEN, STATUS_REOPENED, TYPE_ISSUE } from '~/issues/constants';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import IssuableHeader from '~/vue_shared/issuable/show/components/issuable_header.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import { mockIssuable, mockIssuableShowProps } from '../mock_data';

describe('IssuableHeader component', () => {
  let wrapper;

  const findConfidentialityBadge = () => wrapper.findComponent(ConfidentialityBadge);
  const findStatusBadge = () => wrapper.findComponent(GlBadge);
  const findToggleButton = () => wrapper.findComponent(GlButton);
  const findAuthorLink = () => wrapper.findComponent(GlLink);
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findWorkItemTypeIcon = () => wrapper.findComponent(WorkItemTypeIcon);
  const findIcon = (name) =>
    wrapper
      .findAllComponents(GlIcon)
      .wrappers.find((component) => component.props('name') === name);
  const findBlockedBadge = () => wrapper.findComponent(LockedBadge);
  const findHiddenBadge = () => wrapper.findComponent(HiddenBadge);
  const findImportedBadge = () => wrapper.findComponent(ImportedBadge);
  const findExternalLinkIcon = () => findIcon('external-link');
  const findFirstContributionIcon = () => findIcon('first-contribution');
  const findComponentTooltip = (component) => getBinding(component.element, 'gl-tooltip');

  const createComponent = (props = {}, { stubs } = {}) => {
    wrapper = shallowMount(IssuableHeader, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        ...mockIssuable,
        ...mockIssuableShowProps,
        issuableState: STATUS_OPEN,
        issuableType: TYPE_ISSUE,
        ...props,
      },
      slots: {
        'header-actions': `Header actions slot`,
      },
      stubs: {
        GlSprintf,
        ...stubs,
      },
    });
  };

  describe('status badge', () => {
    describe('variant', () => {
      it('is `success` when status is open', () => {
        createComponent({ issuableState: STATUS_OPEN });

        expect(findStatusBadge().props('variant')).toBe('success');
      });

      it('is `success` when status is reopened', () => {
        createComponent({ issuableState: STATUS_REOPENED });

        expect(findStatusBadge().props('variant')).toBe('success');
      });

      it('is `info` when status is closed', () => {
        createComponent({ issuableState: STATUS_CLOSED });

        expect(findStatusBadge().props('variant')).toBe('info');
      });
    });

    describe('icon', () => {
      it('renders when statusIcon prop exists', () => {
        createComponent({ statusIcon: 'issues' });

        expect(findStatusBadge().props('icon')).toBe('issues');
      });

      it('does not render when statusIcon prop does not exist', () => {
        createComponent({ statusIcon: '' });

        expect(findStatusBadge().findComponent(GlIcon).exists()).toBe(false);
      });
    });

    it('renders status text', () => {
      createComponent();

      expect(findStatusBadge().text()).toBe('Open');
    });
  });

  describe('confidential badge', () => {
    it('renders when issuable is confidential', () => {
      createComponent({ confidential: true });

      expect(findConfidentialityBadge().props()).toEqual({
        issuableType: 'issue',
        workspaceType: 'project',
        hideTextInSmallScreens: false,
      });
    });

    it('does not render when issuable is not confidential', () => {
      createComponent({ confidential: false });

      expect(findConfidentialityBadge().exists()).toBe(false);
    });
  });

  describe('blocked badge', () => {
    it('renders when issuable is blocked', () => {
      createComponent({ blocked: true });

      expect(findBlockedBadge().props('issuableType')).toBe('issue');
    });

    it('does not render when issuable is not blocked', () => {
      createComponent({ blocked: false });

      expect(findBlockedBadge().exists()).toBe(false);
    });
  });

  describe('hidden badge', () => {
    it('renders when issuable is hidden', () => {
      createComponent({ isHidden: true });

      expect(findHiddenBadge().props('issuableType')).toBe('issue');
    });

    it('does not render when issuable is not hidden', () => {
      createComponent({ isHidden: false });

      expect(findHiddenBadge().exists()).toBe(false);
    });
  });

  describe('imported badge', () => {
    it('renders when issuable is imported', () => {
      createComponent({ isImported: true });

      expect(findImportedBadge().props('importableType')).toBe('issue');
    });

    it('does not render when issuable is not imported', () => {
      createComponent({ isImported: false });

      expect(findImportedBadge().exists()).toBe(false);
    });
  });

  describe('work item type icon', () => {
    it('renders when showWorkItemTypeIcon=true and work item type exists', () => {
      createComponent({ showWorkItemTypeIcon: true, issuableType: 'issue' });

      expect(findWorkItemTypeIcon().props()).toMatchObject({
        showText: true,
        workItemType: 'issue',
      });
    });

    it('does not render when showWorkItemTypeIcon=false', () => {
      createComponent({ showWorkItemTypeIcon: false });

      expect(findWorkItemTypeIcon().exists()).toBe(false);
    });
  });

  describe('timeago tooltip', () => {
    it('renders', () => {
      createComponent();

      expect(findTimeAgoTooltip().props('time')).toBe('2020-06-29T13:52:56Z');
    });
  });

  describe('author', () => {
    it('renders link', () => {
      createComponent();

      expect(findAuthorLink().text()).toContain('Administrator');
      expect(findAuthorLink().attributes()).toMatchObject({
        href: 'http://0.0.0.0:3000/root',
        'data-user-id': '1',
      });
      expect(findAuthorLink().classes()).toContain('js-user-link');
    });

    describe('when author exists outside of GitLab', () => {
      it('renders external link icon', () => {
        createComponent({ author: { webUrl: 'https://example.com/test-user' } });

        expect(findExternalLinkIcon().props('ariaLabel')).toBe('external link');
      });
    });
  });

  describe('first contribution icon', () => {
    it('renders when isFirstContribution=true', () => {
      createComponent({ isFirstContribution: true });

      expect(findFirstContributionIcon().props('ariaLabel')).toBe('1st contribution!');
    });

    it('has tooltip', () => {
      createComponent({ isFirstContribution: true });

      expect(findComponentTooltip(findFirstContributionIcon())).toBeDefined();
      expect(findFirstContributionIcon().attributes('title')).toBe('1st contribution!');
    });

    it('does not render when isFirstContribution=false', () => {
      createComponent({ isFirstContribution: false });

      expect(findFirstContributionIcon()).toBeUndefined();
    });
  });

  describe('task status', () => {
    it('renders task status text when `taskCompletionStatus` prop is defined', () => {
      createComponent();

      expect(wrapper.text()).toContain('0 of 5 checklist items completed');
    });

    it('does not render task status text when tasks count is 0', () => {
      createComponent({ taskCompletionStatus: { count: 0, completedCount: 0 } });

      expect(wrapper.text()).not.toContain('checklist item');
    });
  });

  describe('sidebar toggle button', () => {
    beforeEach(() => {
      setHTMLFixture('<button class="js-toggle-right-sidebar-button">Collapse sidebar</button>');
      createComponent();
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('renders', () => {
      expect(findToggleButton().props('icon')).toBe('chevron-double-lg-left');
      expect(findToggleButton().attributes('aria-label')).toBe('Expand sidebar');
    });

    describe('when clicked', () => {
      it('emits a "toggle" event', () => {
        findToggleButton().vm.$emit('click');

        expect(wrapper.emitted('toggle')).toEqual([[]]);
      });

      it('dispatches `click` event on sidebar toggle button', () => {
        const toggleSidebarButton = document.querySelector('.js-toggle-right-sidebar-button');
        const dispatchEvent = jest
          .spyOn(toggleSidebarButton, 'dispatchEvent')
          .mockImplementation(jest.fn);

        findToggleButton().vm.$emit('click');

        expect(dispatchEvent).toHaveBeenCalledWith(expect.objectContaining({ type: 'click' }));
      });
    });
  });

  describe('header actions', () => {
    it('renders slot', () => {
      createComponent();

      expect(wrapper.text()).toContain('Header actions slot');
    });
  });
});

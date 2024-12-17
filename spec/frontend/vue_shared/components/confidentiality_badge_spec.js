import { GlBadge, GlIcon } from '@gitlab/ui';

import { shallowMount } from '@vue/test-utils';
import { TYPE_ISSUE, TYPE_EPIC, WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';

import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';

const createComponent = ({
  workspaceType = WORKSPACE_PROJECT,
  issuableType = TYPE_ISSUE,
  hideTextInSmallScreens = false,
} = {}) =>
  shallowMount(ConfidentialityBadge, {
    propsData: {
      workspaceType,
      issuableType,
      hideTextInSmallScreens,
    },
  });

describe('ConfidentialityBadge', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  const findConfidentialityBadgeText = () =>
    wrapper.find('[data-testid="confidential-badge-text"]');
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findBadgeIcon = () => wrapper.findComponent(GlIcon);

  it.each`
    workspaceType        | issuableType  | expectedTooltip
    ${WORKSPACE_PROJECT} | ${TYPE_ISSUE} | ${'Only project members with at least the Planner role, the author, and assignees can view or be notified about this issue.'}
    ${WORKSPACE_GROUP}   | ${TYPE_EPIC}  | ${'Only group members with at least the Planner role can view or be notified about this epic.'}
  `(
    'should render gl-badge with correct tooltip when workspaceType is $workspaceType and issuableType is $issuableType',
    ({ workspaceType, issuableType, expectedTooltip }) => {
      wrapper = createComponent({
        workspaceType,
        issuableType,
      });

      expect(findBadgeIcon().props('name')).toBe('eye-slash');
      expect(findBadge().props()).toMatchObject({
        variant: 'warning',
      });
      expect(findBadge().attributes('title')).toBe(expectedTooltip);
      expect(findBadge().text()).toBe('Confidential');
    },
  );

  describe('hideTextInSmallScreens', () => {
    it('does not have `gl-sr-only` and `sm:gl-not-sr-only` when `hideTextInSmallScreens` is false', () => {
      wrapper = createComponent({ hideTextInSmallScreens: false });

      expect(findConfidentialityBadgeText().classes()).not.toContain('gl-sr-only');
      expect(findConfidentialityBadgeText().classes()).not.toContain('sm:gl-not-sr-only');
    });

    it('has `gl-sr-only` and `sm:gl-not-sr-only` when `hideTextInSmallScreens` is true', () => {
      wrapper = createComponent({ hideTextInSmallScreens: true });

      expect(findConfidentialityBadgeText().classes()).toContain('gl-sr-only');
      expect(findConfidentialityBadgeText().classes()).toContain('sm:gl-not-sr-only');
    });
  });
});

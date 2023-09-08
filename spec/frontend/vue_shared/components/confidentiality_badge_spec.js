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
    ${WORKSPACE_PROJECT} | ${TYPE_ISSUE} | ${'Only project members with at least the Reporter role, the author, and assignees can view or be notified about this issue.'}
    ${WORKSPACE_GROUP}   | ${TYPE_EPIC}  | ${'Only group members with at least the Reporter role can view or be notified about this epic.'}
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

  it('does not have `gl-sm-display-block` and `gl-display-none` when `hideTextInSmallScreens` is false', () => {
    wrapper = createComponent({ hideTextInSmallScreens: false });

    expect(findConfidentialityBadgeText().classes()).not.toContain(
      'gl-display-none',
      'gl-sm-display-block',
    );
  });

  it('has `gl-sm-display-block` and `gl-display-none` when `hideTextInSmallScreens` is true', () => {
    wrapper = createComponent({ hideTextInSmallScreens: true });

    expect(findConfidentialityBadgeText().classes()).toContain(
      'gl-display-none',
      'gl-sm-display-block',
    );
  });
});

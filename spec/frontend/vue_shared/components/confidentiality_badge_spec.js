import { GlBadge } from '@gitlab/ui';

import { shallowMount } from '@vue/test-utils';
import { WorkspaceType, TYPE_ISSUE, TYPE_EPIC } from '~/issues/constants';

import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';

const createComponent = ({
  workspaceType = WorkspaceType.project,
  issuableType = TYPE_ISSUE,
} = {}) =>
  shallowMount(ConfidentialityBadge, {
    propsData: {
      workspaceType,
      issuableType,
    },
  });

describe('ConfidentialityBadge', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    workspaceType            | issuableType  | expectedTooltip
    ${WorkspaceType.project} | ${TYPE_ISSUE} | ${'Only project members with at least the Reporter role, the author, and assignees can view or be notified about this issue.'}
    ${WorkspaceType.group}   | ${TYPE_EPIC}  | ${'Only group members with at least the Reporter role can view or be notified about this epic.'}
  `(
    'should render gl-badge with correct tooltip when workspaceType is $workspaceType and issuableType is $issuableType',
    ({ workspaceType, issuableType, expectedTooltip }) => {
      wrapper = createComponent({
        workspaceType,
        issuableType,
      });

      const badgeEl = wrapper.findComponent(GlBadge);

      expect(badgeEl.props()).toMatchObject({
        icon: 'eye-slash',
        variant: 'warning',
      });
      expect(badgeEl.attributes('title')).toBe(expectedTooltip);
      expect(badgeEl.text()).toBe('Confidential');
    },
  );
});

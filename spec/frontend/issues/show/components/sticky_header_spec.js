import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import {
  issuableStatusText,
  STATUS_CLOSED,
  STATUS_OPEN,
  STATUS_REOPENED,
  TYPE_EPIC,
  TYPE_INCIDENT,
  TYPE_ISSUE,
} from '~/issues/constants';
import StickyHeader from '~/issues/show/components/sticky_header.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';

describe('StickyHeader component', () => {
  let wrapper;

  const findConfidentialBadge = () => wrapper.findComponent(ConfidentialityBadge);
  const findHiddenBadge = () => wrapper.findComponent(HiddenBadge);
  const findLockedBadge = () => wrapper.findComponent(LockedBadge);
  const findTitle = () => wrapper.findComponent(GlLink);

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(StickyHeader, {
      propsData: {
        issuableStatus: STATUS_OPEN,
        issuableType: TYPE_ISSUE,
        show: true,
        title: 'A sticky issue',
        ...props,
      },
    });
  };

  it.each`
    issuableType     | issuableStatus   | statusIcon
    ${TYPE_INCIDENT} | ${STATUS_OPEN}   | ${'issue-open-m'}
    ${TYPE_INCIDENT} | ${STATUS_CLOSED} | ${'issue-close'}
    ${TYPE_ISSUE}    | ${STATUS_OPEN}   | ${'issue-open-m'}
    ${TYPE_ISSUE}    | ${STATUS_CLOSED} | ${'issue-close'}
    ${TYPE_EPIC}     | ${STATUS_OPEN}   | ${'issue-open-m'}
    ${TYPE_EPIC}     | ${STATUS_CLOSED} | ${'issue-close'}
  `(
    'shows with state icon "$statusIcon" for $issuableType when status is $issuableStatus',
    ({ issuableType, issuableStatus, statusIcon }) => {
      createComponent({ issuableType, issuableStatus });

      expect(wrapper.findComponent(GlIcon).props('name')).toBe(statusIcon);
    },
  );

  it.each`
    title                                        | issuableStatus
    ${'shows with Open when status is opened'}   | ${STATUS_OPEN}
    ${'shows with Closed when status is closed'} | ${STATUS_CLOSED}
    ${'shows with Open when status is reopened'} | ${STATUS_REOPENED}
  `('$title', ({ issuableStatus }) => {
    createComponent({ issuableStatus });

    expect(wrapper.text()).toContain(issuableStatusText[issuableStatus]);
  });

  it.each`
    title                                                                | isConfidential
    ${'does not show confidential badge when issue is not confidential'} | ${false}
    ${'shows confidential badge when issue is confidential'}             | ${true}
  `('$title', ({ isConfidential }) => {
    createComponent({ isConfidential });
    const confidentialBadge = findConfidentialBadge();

    expect(confidentialBadge.exists()).toBe(isConfidential);

    if (isConfidential) {
      expect(confidentialBadge.props()).toMatchObject({
        workspaceType: 'project',
        issuableType: 'issue',
      });
    }
  });

  it.each`
    title                                                    | isLocked
    ${'does not show locked badge when issue is not locked'} | ${false}
    ${'shows locked badge when issue is locked'}             | ${true}
  `('$title', ({ isLocked }) => {
    createComponent({ isLocked });
    const lockedBadge = findLockedBadge();

    expect(lockedBadge.exists()).toBe(isLocked);
  });

  it.each`
    title                                                    | isHidden
    ${'does not show hidden badge when issue is not hidden'} | ${false}
    ${'shows hidden badge when issue is hidden'}             | ${true}
  `('$title', ({ isHidden }) => {
    createComponent({ isHidden });
    const hiddenBadge = findHiddenBadge();

    expect(hiddenBadge.exists()).toBe(isHidden);
  });

  it('shows with title', () => {
    createComponent();
    const title = findTitle();

    expect(title.text()).toContain('A sticky issue');
    expect(title.attributes('href')).toBe('#top');
  });
});

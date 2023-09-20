import { GlIcon } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
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
  const findHiddenBadge = () => wrapper.findByTestId('hidden');
  const findLockedBadge = () => wrapper.findByTestId('locked');

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(StickyHeader, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        issuableStatus: STATUS_OPEN,
        issuableType: TYPE_ISSUE,
        show: true,
        title: 'A sticky issue',
        titleHtml: '',
        ...props,
      },
    });
  };

  it.each`
    issuableType     | issuableStatus   | statusIcon
    ${TYPE_INCIDENT} | ${STATUS_OPEN}   | ${'issues'}
    ${TYPE_INCIDENT} | ${STATUS_CLOSED} | ${'issue-closed'}
    ${TYPE_ISSUE}    | ${STATUS_OPEN}   | ${'issues'}
    ${TYPE_ISSUE}    | ${STATUS_CLOSED} | ${'issue-closed'}
    ${TYPE_EPIC}     | ${STATUS_OPEN}   | ${'epic'}
    ${TYPE_EPIC}     | ${STATUS_CLOSED} | ${'epic-closed'}
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

    if (isLocked) {
      expect(lockedBadge.attributes('title')).toBe(
        'This issue is locked. Only project members can comment.',
      );
      expect(getBinding(lockedBadge.element, 'gl-tooltip')).not.toBeUndefined();
    }
  });

  it.each`
    title                                                    | isHidden
    ${'does not show hidden badge when issue is not hidden'} | ${false}
    ${'shows hidden badge when issue is hidden'}             | ${true}
  `('$title', ({ isHidden }) => {
    createComponent({ isHidden });
    const hiddenBadge = findHiddenBadge();

    expect(hiddenBadge.exists()).toBe(isHidden);

    if (isHidden) {
      expect(hiddenBadge.attributes('title')).toBe(
        'This issue is hidden because its author has been banned',
      );
      expect(getBinding(hiddenBadge.element, 'gl-tooltip')).not.toBeUndefined();
    }
  });

  it('shows with title', () => {
    createComponent();
    const title = wrapper.find('a');

    expect(title.text()).toContain('A sticky issue');
    expect(title.attributes('href')).toBe('#top');
  });

  it('shows title containing markup', () => {
    const titleHtml = '<b>A sticky issue</b>';
    createComponent({ titleHtml });

    expect(wrapper.find('a').html()).toContain(titleHtml);
  });
});

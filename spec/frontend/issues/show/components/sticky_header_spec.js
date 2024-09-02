import { GlBadge, GlLink, GlSprintf } from '@gitlab/ui';
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
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';

describe('StickyHeader component', () => {
  let wrapper;

  const findConfidentialBadge = () => wrapper.findComponent(ConfidentialityBadge);
  const findHiddenBadge = () => wrapper.findComponent(HiddenBadge);
  const findImportedBadge = () => wrapper.findComponent(ImportedBadge);
  const findLockedBadge = () => wrapper.findComponent(LockedBadge);
  const findTitle = () => wrapper.findComponent(GlLink);
  const findClosedStatusLink = () =>
    wrapper.find('[data-testid="sticky-header-closed-status-link"');
  const findIssuableHeader = () => wrapper.findComponent(StickyHeader);

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(StickyHeader, {
      propsData: {
        issuableState: STATUS_OPEN,
        issuableType: TYPE_ISSUE,
        movedToIssueUrl: '',
        promotedToEpicUrl: '',
        duplicatedToIssueUrl: '',
        show: true,
        title: 'A sticky issue',
        ...props,
      },
      stubs: {
        GlBadge,
        GlSprintf,
        GlLink,
      },
    });
  };

  it.each`
    issuableType     | issuableState    | statusIcon
    ${TYPE_INCIDENT} | ${STATUS_OPEN}   | ${'issue-open-m'}
    ${TYPE_INCIDENT} | ${STATUS_CLOSED} | ${'issue-close'}
    ${TYPE_ISSUE}    | ${STATUS_OPEN}   | ${'issue-open-m'}
    ${TYPE_ISSUE}    | ${STATUS_CLOSED} | ${'issue-close'}
    ${TYPE_EPIC}     | ${STATUS_OPEN}   | ${'issue-open-m'}
    ${TYPE_EPIC}     | ${STATUS_CLOSED} | ${'issue-close'}
  `(
    'shows with state icon "$statusIcon" for $issuableType when status is $issuableState',
    ({ issuableType, issuableState, statusIcon }) => {
      createComponent({ issuableType, issuableState });

      expect(wrapper.findComponent(GlBadge).props('icon')).toBe(statusIcon);
    },
  );

  it.each`
    title                                        | issuableState
    ${'shows with Open when status is opened'}   | ${STATUS_OPEN}
    ${'shows with Closed when status is closed'} | ${STATUS_CLOSED}
    ${'shows with Open when status is reopened'} | ${STATUS_REOPENED}
  `('$title', ({ issuableState }) => {
    createComponent({ issuableState });

    expect(wrapper.text()).toContain(issuableStatusText[issuableState]);
  });

  describe('when status is closed', () => {
    beforeEach(() => {
      createComponent({ issuableState: STATUS_CLOSED });
    });

    describe('when issue is marked as duplicate', () => {
      beforeEach(() => {
        createComponent({
          issuableState: STATUS_CLOSED,
          duplicatedToIssueUrl: 'project/-/issue/5',
        });
      });

      it('renders `Closed (duplicated)`', () => {
        expect(findIssuableHeader().text()).toContain('Closed (duplicated)');
      });

      it('links to the duplicated issue', () => {
        expect(findClosedStatusLink().attributes('href')).toBe('project/-/issue/5');
      });
    });

    describe('when issue is marked as moved', () => {
      beforeEach(() => {
        createComponent({ issuableState: STATUS_CLOSED, movedToIssueUrl: 'project/-/issue/6' });
      });

      it('renders `Closed (moved)`', () => {
        expect(findIssuableHeader().text()).toContain('Closed (moved)');
      });

      it('links to the moved issue', () => {
        expect(findClosedStatusLink().attributes('href')).toBe('project/-/issue/6');
      });
    });

    describe('when issue is marked as promoted', () => {
      beforeEach(() => {
        createComponent({ issuableState: STATUS_CLOSED, promotedToEpicUrl: 'group/-/epic/7' });
      });

      it('renders `Closed (promoted)`', () => {
        expect(findIssuableHeader().text()).toContain('Closed (promoted)');
      });

      it('links to the promoted epic', () => {
        expect(findClosedStatusLink().attributes('href')).toBe('group/-/epic/7');
      });
    });
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

  it.each`
    title                                                        | isImported
    ${'does not show imported badge when issue is not imported'} | ${false}
    ${'shows imported badge when issue is imported'}             | ${true}
  `('$title', ({ isImported }) => {
    createComponent({ isImported });

    expect(findImportedBadge().exists()).toBe(isImported);
  });

  it('shows with title', () => {
    createComponent();
    const title = findTitle();

    expect(title.text()).toContain('A sticky issue');
    expect(title.attributes('href')).toBe('#top');
  });
});

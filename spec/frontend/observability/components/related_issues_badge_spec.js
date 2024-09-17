import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import RelatedIssuesBadge from '~/observability/components/related_issues_badge.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { scrollToElement } from '~/lib/utils/common_utils';

jest.mock('~/alert');
jest.mock('~/lib/utils/common_utils');

describe('RelatedIssuesBadge', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findErrorBadge = () => wrapper.findByTestId('error-badge');
  const findTotalBadge = () => wrapper.findByTestId('total-badge');

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(RelatedIssuesBadge, {
      propsData: {
        issuesTotal: 3,
        loading: false,
        error: null,
        anchorId: 'anchor',
        parentScrollingId: 'parent',
        ...props,
      },
    });
  };

  describe('default behaviour', () => {
    beforeEach(() => createWrapper());

    it('renders the count badge and link', () => {
      expect(findErrorBadge().exists()).toBe(false);
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findButton().text()).toContain('View issues');
      expect(findTotalBadge().text()).toBe('3');
    });

    it('scrolls to the element when clicked', () => {
      findButton().vm.$emit('click');

      expect(scrollToElement).toHaveBeenCalledWith('#anchor', {
        parent: '#parent',
      });
    });
  });

  describe('when loading=true', () => {
    beforeEach(() => createWrapper({ loading: true }));

    it('shows the loading icon and hides the other badges', () => {
      expect(findTotalBadge().exists()).toBe(false);
      expect(findErrorBadge().exists()).toBe(false);
      expect(findButton().text()).toContain('View issues');
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when there is an error', () => {
    beforeEach(() => createWrapper({ error: 'Foo bar' }));

    it('shows the error badge and hides the other badges and loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findTotalBadge().exists()).toBe(false);
      expect(findButton().text()).toContain('View issues');
      expect(findErrorBadge().attributes('title')).toBe(
        'Failed to load related issues. Try reloading the page.',
      );
    });
  });
});

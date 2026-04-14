import { GlPopover, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RapidDiffsToggle from '~/rapid_diffs/app/rapid_diffs_toggle.vue';
import { setCookie, removeCookie, getCookie } from '~/lib/utils/common_utils';
import { RAPID_DIFFS_COOKIE_NAME } from '~/rapid_diffs/constants';
import { helpPagePath } from '~/helpers/help_page_helper';

jest.mock('~/lib/utils/common_utils');
const FEEDBACK_ISSUE_PATH = 'https://gitlab.com/gitlab-org/gitlab/-/work_items/596236';
const DOCS_URL = helpPagePath('user/project/merge_requests/changes', { anchor: 'rapid-diffs' });

describe('RapidDiffsToggle', () => {
  let wrapper;

  const findTryButton = () => wrapper.findByTestId('rapid-diffs-try-button');
  const findBadge = () => wrapper.findByTestId('rapid-diffs-beta-badge');
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findLearnMoreButton = () => wrapper.findByTestId('rapid-diffs-learn-more-button');
  const findDropdown = () => wrapper.findByTestId('rapid-diffs-dropdown');
  const findDropdownGroups = () => wrapper.findAllComponents(GlDisclosureDropdownGroup);

  const createComponent = (cookieValue = null) => {
    getCookie.mockReturnValue(cookieValue);
    wrapper = shallowMountExtended(RapidDiffsToggle);
  };

  beforeEach(() => {
    delete window.location;
    window.location = { reload: jest.fn() };
  });

  describe('when disabled', () => {
    beforeEach(() => createComponent(null));

    it('renders the try button with beta badge and popover', () => {
      expect(findTryButton().props()).toMatchObject({ variant: 'confirm', category: 'tertiary' });
      expect(findBadge().text()).toBe('Beta');
      expect(findPopover().props('title')).toBe('Improved performance loading diffs');
      expect(findLearnMoreButton().attributes('href')).toBe(DOCS_URL);
    });

    it('sets cookie and reloads on click', () => {
      findTryButton().vm.$emit('click');
      expect(setCookie).toHaveBeenCalledWith(RAPID_DIFFS_COOKIE_NAME, 'true');
      expect(window.location.reload).toHaveBeenCalled();
    });
  });

  describe('when enabled', () => {
    beforeEach(() => createComponent('true'));

    it('renders the dropdown with two groups separated by a divider', () => {
      const dropdown = findDropdown();
      expect(dropdown.exists()).toBe(true);
      expect(dropdown.props('toggleText')).toBe('Rapid Diffs');

      const groups = findDropdownGroups();
      expect(groups).toHaveLength(2);

      const infoGroup = groups.at(0);
      expect(infoGroup.props('bordered')).toBe(false);
      expect(infoGroup.props('group').items).toEqual([
        expect.objectContaining({ text: 'Learn more', href: DOCS_URL, icon: 'question-o' }),
        expect.objectContaining({
          text: 'Leave feedback',
          href: FEEDBACK_ISSUE_PATH,
          icon: 'comment-dots',
        }),
      ]);

      const switchGroup = groups.at(1);
      expect(switchGroup.props('bordered')).toBe(true);
      expect(switchGroup.props('group').items).toEqual([
        expect.objectContaining({ text: 'Switch to classic loading' }),
      ]);
    });

    it('removes cookie and reloads when switching to classic', () => {
      const switchGroup = findDropdownGroups().at(1);
      switchGroup.props('group').items[0].action();
      expect(removeCookie).toHaveBeenCalledWith(RAPID_DIFFS_COOKIE_NAME);
      expect(window.location.reload).toHaveBeenCalled();
    });
  });
});

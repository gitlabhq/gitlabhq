import { GlPopover, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RapidDiffsToggle from '~/rapid_diffs/app/rapid_diffs_toggle.vue';
import Api from '~/api';
import Tracking from '~/tracking';
import { SERVICE_PING_SCHEMA } from '~/tracking/constants';
import { setCookie, removeCookie, getCookie } from '~/lib/utils/common_utils';
import { RAPID_DIFFS_COOKIE_NAME } from '~/rapid_diffs/constants';
import { helpPagePath } from '~/helpers/help_page_helper';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/api');
jest.mock('~/tracking');
const FEEDBACK_ISSUE_PATH = 'https://gitlab.com/gitlab-org/gitlab/-/work_items/596236';
const DOCS_URL = helpPagePath('user/project/merge_requests/changes', { anchor: 'rapid-diffs' });

describe('RapidDiffsToggle', () => {
  let wrapper;

  useMockLocationHelper();

  const findTryButton = () => wrapper.findByTestId('rapid-diffs-try-button');
  const findBadge = () => wrapper.findByTestId('rapid-diffs-beta-badge');
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findLearnMoreButton = () => wrapper.findByTestId('rapid-diffs-learn-more-button');
  const findDropdown = () => wrapper.findByTestId('rapid-diffs-dropdown');
  const findDropdownGroups = () => wrapper.findAllComponents(GlDisclosureDropdownGroup);

  const GlDisclosureDropdownStub = {
    template: `<div v-bind="$attrs"><slot name="toggle" v-bind="{ accessibilityAttributes: {} }" /><slot /></div>`,
  };

  const createComponent = (cookieValue = null) => {
    getCookie.mockReturnValue(cookieValue);
    wrapper = shallowMountExtended(RapidDiffsToggle, {
      stubs: { GlDisclosureDropdown: GlDisclosureDropdownStub },
    });
  };

  describe('when disabled', () => {
    beforeEach(() => {
      window.location.href = 'https://example.com/diffs?rapid_diffs_disabled=true';
      createComponent(null);
    });

    it('renders the try button with beta badge and popover', () => {
      expect(findTryButton().props()).toMatchObject({ variant: 'confirm', category: 'tertiary' });
      expect(findBadge().text()).toBe('Beta');
      expect(findPopover().props('title')).toBe('Improved performance loading diffs');
      expect(findPopover().text()).toContain('Some classic diff features are not yet available.');
      expect(findLearnMoreButton().attributes('href')).toBe(DOCS_URL);
    });

    it('tracks event, sets cookie, and reloads on click', async () => {
      Api.trackInternalEvent.mockResolvedValue();
      findTryButton().vm.$emit('click');
      await waitForPromises();
      expect(Tracking.event).toHaveBeenCalledWith(undefined, 'toggle_rapid_diffs', {
        context: {
          schema: SERVICE_PING_SCHEMA,
          data: { event_name: 'toggle_rapid_diffs', data_source: 'redis_hll' },
        },
        label: 'enabled',
      });
      expect(Api.trackInternalEvent).toHaveBeenCalledWith('toggle_rapid_diffs', {
        label: 'enabled',
      });
      expect(setCookie).toHaveBeenCalledWith(RAPID_DIFFS_COOKIE_NAME, 'true');
      expect(window.location.assign).toHaveBeenCalledWith('https://example.com/diffs');
    });
  });

  describe('when enabled', () => {
    beforeEach(() => {
      window.location.href = 'https://example.com/diffs?rapid_diffs=true';
      createComponent('true');
    });

    it('renders the dropdown with beta badge and two groups separated by a divider', () => {
      const dropdown = findDropdown();
      expect(dropdown.exists()).toBe(true);
      expect(findBadge().text()).toBe('Beta');

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

    it('tracks event, removes cookie, and reloads when switching to classic', async () => {
      Api.trackInternalEvent.mockResolvedValue();
      const switchGroup = findDropdownGroups().at(1);
      switchGroup.props('group').items[0].action();
      await waitForPromises();
      expect(Tracking.event).toHaveBeenCalledWith(undefined, 'toggle_rapid_diffs', {
        context: {
          schema: SERVICE_PING_SCHEMA,
          data: { event_name: 'toggle_rapid_diffs', data_source: 'redis_hll' },
        },
        label: 'disabled',
      });
      expect(Api.trackInternalEvent).toHaveBeenCalledWith('toggle_rapid_diffs', {
        label: 'disabled',
      });
      expect(removeCookie).toHaveBeenCalledWith(RAPID_DIFFS_COOKIE_NAME);
      expect(window.location.assign).toHaveBeenCalledWith('https://example.com/diffs');
    });
  });
});

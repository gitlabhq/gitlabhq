import { GlBadge, GlDisclosureDropdown } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MergeRequestMenu from '~/super_sidebar/components/merge_request_menu.vue';
import { userCounts } from '~/super_sidebar/user_counts_manager';
import { mergeRequestMenuGroup } from '../mock_data';

describe('MergeRequestMenu component', () => {
  let wrapper;

  const findGlBadge = (at) => wrapper.findAllComponents(GlBadge).at(at);
  const findGlDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findLink = (name) => wrapper.findByRole('link', { name });

  const createWrapper = (items) => {
    wrapper = mountExtended(MergeRequestMenu, {
      propsData: {
        items,
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper(mergeRequestMenuGroup);
    });

    it('passes the items to the disclosure dropdown', () => {
      expect(findGlDisclosureDropdown().props('items')).toBe(mergeRequestMenuGroup);
    });

    it.each(mergeRequestMenuGroup[0].items)('renders item text and count in link', (item) => {
      const index = mergeRequestMenuGroup[0].items.indexOf(item);
      const { text, href, count, extraAttrs } = mergeRequestMenuGroup[0].items[index];
      const link = findLink(new RegExp(text));

      expect(link.text()).toContain(text);
      expect(link.text()).toContain(String(count));
      expect(link.attributes('href')).toBe(href);
      expect(link.attributes('data-track-action')).toBe(extraAttrs['data-track-action']);
      expect(link.attributes('data-track-label')).toBe(extraAttrs['data-track-label']);
      expect(link.attributes('data-track-property')).toBe(extraAttrs['data-track-property']);
      expect(link.attributes('class')).toContain(extraAttrs.class);
    });

    it('renders item count string in badge', () => {
      const { count } = mergeRequestMenuGroup[0].items[0];
      expect(findGlBadge(0).text()).toBe(String(count));
    });

    it('renders 0 string when count is empty', () => {
      expect(findGlBadge(1).text()).toBe(String(0));
    });

    it('renders value from userCounts if `userCount` prop is defined', () => {
      userCounts.assigned_merge_requests = 5;
      mergeRequestMenuGroup[0].items[0].userCount = 'assigned_merge_requests';
      createWrapper(mergeRequestMenuGroup);

      expect(findGlBadge(0).text()).toBe(String(userCounts.assigned_merge_requests));
    });

    it('renders item count if unknown `userCount` prop is defined', () => {
      const { count } = mergeRequestMenuGroup[0].items[0];
      mergeRequestMenuGroup[0].items[0].userCount = 'foobar';
      createWrapper(mergeRequestMenuGroup);

      expect(findGlBadge(0).text()).toBe(String(count));
    });
  });
});

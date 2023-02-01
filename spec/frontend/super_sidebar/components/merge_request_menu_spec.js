import { GlBadge, GlDisclosureDropdown } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MergeRequestMenu from '~/super_sidebar/components/merge_request_menu.vue';
import { mergeRequestMenuGroup } from '../mock_data';

describe('MergeRequestMenu component', () => {
  let wrapper;

  const findGlBadge = (at) => wrapper.findAllComponents(GlBadge).at(at);
  const findGlDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findLink = () => wrapper.findByRole('link');

  const createWrapper = () => {
    wrapper = mountExtended(MergeRequestMenu, {
      propsData: {
        items: mergeRequestMenuGroup,
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('passes the items to the disclosure dropdown', () => {
      expect(findGlDisclosureDropdown().props('items')).toBe(mergeRequestMenuGroup);
    });

    it('renders item text and count in link', () => {
      const { text, href, count } = mergeRequestMenuGroup[0].items[0];
      expect(findLink().text()).toContain(text);
      expect(findLink().text()).toContain(String(count));
      expect(findLink().attributes('href')).toBe(href);
    });

    it('renders item count string in badge', () => {
      const { count } = mergeRequestMenuGroup[0].items[0];
      expect(findGlBadge(0).text()).toBe(String(count));
    });

    it('renders 0 string when count is empty', () => {
      expect(findGlBadge(1).text()).toBe(String(0));
    });
  });
});

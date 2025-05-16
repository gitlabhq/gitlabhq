import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RegularAccessSummary from '~/admin/users/components/user_type/regular_access_summary.vue';
import AccessSummary from '~/admin/users/components/user_type/access_summary.vue';
import { RENDER_ALL_SLOTS_TEMPLATE, stubComponent } from 'helpers/stub_component';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';

describe('RegularAccessSummary component', () => {
  let wrapper;

  const createWrapper = (slotContent) => {
    wrapper = shallowMountExtended(RegularAccessSummary, {
      scopedSlots: slotContent ? { default: slotContent } : null,
      stubs: {
        GlSprintf,
        AccessSummary: stubComponent(AccessSummary, { template: RENDER_ALL_SLOTS_TEMPLATE }),
      },
    });
  };

  const findAdminListItem = () => wrapper.findByTestId('slot-admin-list').find('li');
  const findGroupListItem = () => wrapper.findByTestId('slot-group-list').find('li');
  const findSettingsListItem = () => wrapper.findByTestId('slot-settings-list').find('li');

  describe('access summary', () => {
    beforeEach(() => createWrapper());

    it('shows access summary', () => {
      expect(wrapper.findComponent(AccessSummary).exists()).toBe(true);
    });

    it('shows admin list item', () => {
      expect(findAdminListItem().text()).toBe('No access.');
    });

    describe('group section', () => {
      it('shows list item', () => {
        expect(findGroupListItem().text()).toMatchInterpolatedText(
          'Based on member role in groups and projects. Learn more about member roles.',
        );
      });

      it('shows link', () => {
        const link = findGroupListItem().findComponent(HelpPageLink);

        expect(link.text()).toBe('Learn more about member roles.');
        expect(link.props('href')).toBe('user/permissions');
        expect(link.attributes('target')).toBe('_blank');
      });
    });

    it('shows settings list item', () => {
      expect(findSettingsListItem().text()).toBe(
        'Requires at least Maintainer role in specific groups and projects.',
      );
    });
  });

  describe('when admin slot content is provided', () => {
    beforeEach(() => createWrapper('<div>admin slot content</div>'));

    it('shows slot content', () => {
      expect(wrapper.findByTestId('slot-admin-content').text()).toBe('admin slot content');
    });

    it('does not show admin list item', () => {
      expect(wrapper.findByTestId('slot-admin-list').exists()).toBe(false);
    });
  });
});

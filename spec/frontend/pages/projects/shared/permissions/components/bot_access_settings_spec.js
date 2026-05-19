import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupSelect from '~/vue_shared/components/entity_select/group_select.vue';
import BotAccessSettings from '~/pages/projects/shared/permissions/components/bot_access_settings.vue';

describe('BotAccessSettings', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(BotAccessSettings, { propsData: props });
  };

  const findGroupSelect = () => wrapper.findComponent(GroupSelect);

  describe('group selector', () => {
    it('does not show group selector when bot access is disabled', () => {
      createComponent({ enabled: false });

      expect(findGroupSelect().exists()).toBe(false);
    });

    it('shows group selector when bot access is enabled', () => {
      createComponent({ enabled: true });

      expect(findGroupSelect().exists()).toBe(true);
    });

    it('passes initial group ID to group selector', () => {
      createComponent({ enabled: true, groupId: 42 });

      expect(findGroupSelect().props('initialSelection')).toBe(42);
    });

    it('passes root group ID as string to group selector for filtering', () => {
      createComponent({ enabled: true, rootGroupId: 100 });

      const groupSelect = findGroupSelect();
      expect(groupSelect.props('parentGroupID')).toBe('100');
      expect(groupSelect.props('groupsFilter')).toBe('descendant_groups');
    });

    it('renders group selector without parent filter when rootGroupId is null', () => {
      createComponent({ enabled: true, rootGroupId: null });

      const groupSelect = findGroupSelect();
      expect(groupSelect.props('parentGroupID')).toBeNull();
      expect(groupSelect.props('groupsFilter')).toBeNull();
    });
  });
});

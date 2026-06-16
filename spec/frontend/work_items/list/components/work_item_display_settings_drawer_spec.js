import { GlDrawer } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemDisplaySettingsDrawer from '~/work_items/list/components/work_item_display_settings_drawer.vue';
import WorkItemDisplaySettingsSort from '~/work_items/list/components/work_item_display_settings_sort.vue';
import WorkItemDisplaySettingsMetadata from '~/work_items/list/components/work_item_display_settings_metadata.vue';
import WorkItemDisplaySettingsUserPreferences from '~/work_items/list/components/work_item_display_settings_user_preferences.vue';

const SORT_OPTIONS = [
  {
    id: 1,
    title: 'Created date',
    sortDirection: { ascending: 'CREATED_ASC', descending: 'CREATED_DESC' },
  },
];

const DEFAULT_PROPS = {
  open: false,
  fullPath: 'gitlab-org/gitlab',
  workItemTypeId: 'gid://gitlab/WorkItems::Type/8',
};

describe('WorkItemDisplaySettingsDrawer', () => {
  let wrapper;

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findSort = () => wrapper.findComponent(WorkItemDisplaySettingsSort);
  const findMetadata = () => wrapper.findComponent(WorkItemDisplaySettingsMetadata);
  const findUserPreferences = () => wrapper.findComponent(WorkItemDisplaySettingsUserPreferences);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(WorkItemDisplaySettingsDrawer, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
    });
  };

  it('passes the open prop through to GlDrawer', () => {
    createComponent({ props: { open: true } });

    expect(findDrawer().props('open')).toBe(true);
  });

  it('emits close when GlDrawer emits close', () => {
    createComponent({ props: { open: true } });

    findDrawer().vm.$emit('close');

    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  describe('sort section', () => {
    it('does not render when sortOptions is empty', () => {
      createComponent();

      expect(findSort().exists()).toBe(false);
    });

    it('passes sortOptions and sortKey to the sort component', () => {
      createComponent({
        props: { sortOptions: SORT_OPTIONS, sortKey: 'CREATED_DESC' },
      });

      expect(findSort().props()).toMatchObject({
        sortOptions: SORT_OPTIONS,
        sortKey: 'CREATED_DESC',
      });
    });

    it('re-emits sort when the sort component emits it', () => {
      createComponent({
        props: { sortOptions: SORT_OPTIONS, sortKey: 'CREATED_DESC' },
      });

      findSort().vm.$emit('sort', 'CREATED_ASC');

      expect(wrapper.emitted('sort')).toEqual([['CREATED_ASC']]);
    });
  });

  describe('display settings metadata section', () => {
    it('renders the metadata component with respective props', () => {
      const namespacePreferences = { hiddenMetadataKeys: ['weight'] };
      createComponent({
        props: {
          namespacePreferences,
          isGroup: true,
          isServiceDeskList: false,
          sortKey: 'CREATED_DESC',
        },
      });

      expect(findMetadata().props()).toMatchObject({
        namespacePreferences,
        fullPath: 'gitlab-org/gitlab',
        isGroup: true,
        isServiceDeskList: false,
        workItemTypeId: 'gid://gitlab/WorkItems::Type/8',
        sortKey: 'CREATED_DESC',
      });
    });

    it('re-emits update-settings when the metadata component emits updates', () => {
      createComponent();

      const payload = { hiddenMetadataKeys: ['weight'] };
      findMetadata().vm.$emit('update-settings', payload);

      expect(wrapper.emitted('update-settings')).toEqual([[payload]]);
    });
  });

  describe('user preferences section', () => {
    it('renders the user preferences component with respective props', () => {
      const commonPreferences = { shouldOpenItemsInSidePanel: false };
      createComponent({ props: { commonPreferences } });

      expect(findUserPreferences().props()).toMatchObject({
        commonPreferences,
        fullPath: 'gitlab-org/gitlab',
        workItemTypeId: 'gid://gitlab/WorkItems::Type/8',
      });
    });
  });
});

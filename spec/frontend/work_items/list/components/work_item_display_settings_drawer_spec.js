import { GlDrawer, GlSegmentedControl } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { VIEW_MODE_LIST, VIEW_MODE_BOARD } from '~/work_items/constants';
import WorkItemDisplaySettingsDrawer from '~/work_items/list/components/work_item_display_settings_drawer.vue';
import WorkItemDisplaySettingsSort from '~/work_items/list/components/work_item_display_settings_sort.vue';
import WorkItemDisplaySettingsMetadata from '~/work_items/list/components/work_item_display_settings_metadata.vue';
import WorkItemDisplaySettingsUserPreferences from '~/work_items/list/components/work_item_display_settings_user_preferences.vue';
import WorkItemDisplaySettingsGroupBy from '~/work_items/list/components/work_item_display_settings_group_by.vue';

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
  viewMode: VIEW_MODE_LIST,
};

describe('WorkItemDisplaySettingsDrawer', () => {
  let wrapper;

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findSort = () => wrapper.findComponent(WorkItemDisplaySettingsSort);
  const findMetadata = () => wrapper.findComponent(WorkItemDisplaySettingsMetadata);
  const findUserPreferences = () => wrapper.findComponent(WorkItemDisplaySettingsUserPreferences);
  const findViewModeToggle = () => wrapper.findComponent(GlSegmentedControl);
  const findGroupByRow = () => wrapper.findByTestId('group-by-row');
  const findGroupByBackButton = () => wrapper.findByTestId('group-by-back-button');
  const findGroupBy = () => wrapper.findComponent(WorkItemDisplaySettingsGroupBy);
  const findTitle = () => wrapper.find('h2');

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(WorkItemDisplaySettingsDrawer, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
      provide: {
        glFeatures: { planningViewBoards: true },
        ...provide,
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

  describe('view mode toggles', () => {
    it('renders the toggles with list and board options', () => {
      createComponent();

      expect(findViewModeToggle().exists()).toBe(true);
      expect(findViewModeToggle().props('options')).toEqual([
        {
          value: VIEW_MODE_LIST,
          text: 'List',
          props: { icon: 'list-bulleted' },
        },
        {
          value: VIEW_MODE_BOARD,
          text: 'Board',
          props: { icon: 'work-item-issue-board' },
        },
      ]);
    });

    it('reflects the current chosen view mode', () => {
      createComponent({ props: { viewMode: VIEW_MODE_BOARD } });

      expect(findViewModeToggle().props('value')).toBe(VIEW_MODE_BOARD);
    });

    it('switches view mode with the selected value when toggled', () => {
      createComponent();

      findViewModeToggle().vm.$emit('input', VIEW_MODE_BOARD);

      expect(wrapper.emitted('toggle-view-mode')).toEqual([[VIEW_MODE_BOARD]]);
    });

    it('does not render the toggles when planningViewBoards feature flag is disabled', () => {
      createComponent({ provide: { glFeatures: { planningViewBoards: false } } });

      expect(findViewModeToggle().exists()).toBe(false);
    });
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
          isSavedView: true,
          sortKey: 'CREATED_DESC',
        },
      });

      expect(findMetadata().props()).toMatchObject({
        namespacePreferences,
        fullPath: 'gitlab-org/gitlab',
        isGroup: true,
        isServiceDeskList: false,
        isSavedView: true,
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
      createComponent({ props: { commonPreferences, isSavedView: true } });

      expect(findUserPreferences().props()).toMatchObject({
        commonPreferences,
        fullPath: 'gitlab-org/gitlab',
        isSavedView: true,
        workItemTypeId: 'gid://gitlab/WorkItems::Type/8',
      });
    });
  });

  describe('group by section', () => {
    it('does not render the group by row outside board view mode', () => {
      createComponent({ props: { viewMode: VIEW_MODE_LIST } });

      expect(findGroupByRow().exists()).toBe(false);
    });

    it('does not render the group by row when planningViewBoards is disabled', () => {
      createComponent({
        props: { viewMode: VIEW_MODE_BOARD },
        provide: { glFeatures: { planningViewBoards: false } },
      });

      expect(findGroupByRow().exists()).toBe(false);
    });

    it('renders the group by row with the current strategy label in board view mode', () => {
      createComponent({ props: { viewMode: VIEW_MODE_BOARD } });

      expect(findGroupByRow().text()).toContain('Status');
    });

    it('navigates to the group by sub-page when the row is clicked', async () => {
      createComponent({ props: { viewMode: VIEW_MODE_BOARD, fullPath: 'gitlab-org/gitlab' } });

      await findGroupByRow().trigger('click');

      expect(findTitle().text()).toBe('Group by');
      expect(findGroupBy().props('fullPath')).toBe('gitlab-org/gitlab');
      expect(findMetadata().exists()).toBe(false);
      expect(findSort().exists()).toBe(false);
    });

    it('navigates back to the root page when the back button is clicked', async () => {
      createComponent({ props: { viewMode: VIEW_MODE_BOARD } });
      await findGroupByRow().trigger('click');

      await findGroupByBackButton().vm.$emit('click');

      expect(findTitle().text()).toBe('Display');
      expect(findGroupBy().exists()).toBe(false);
    });

    it('resets to the root page when the drawer closes', async () => {
      createComponent({ props: { open: true, viewMode: VIEW_MODE_BOARD } });
      await findGroupByRow().trigger('click');

      await wrapper.setProps({ open: false });

      expect(findTitle().text()).toBe('Display');
    });
  });
});

import { GlDropdownItem, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';

import DashboardsDropdown from '~/monitoring/components/dashboards_dropdown.vue';

import { dashboardGitResponse } from '../mock_data';

const defaultBranch = 'main';
const starredDashboards = dashboardGitResponse.filter(({ starred }) => starred);
const notStarredDashboards = dashboardGitResponse.filter(({ starred }) => !starred);

describe('DashboardsDropdown', () => {
  let wrapper;
  let mockDashboards;
  let mockSelectedDashboard;

  function createComponent(props, opts = {}) {
    const storeOpts = {
      computed: {
        allDashboards: () => mockDashboards,
        selectedDashboard: () => mockSelectedDashboard,
      },
    };

    wrapper = shallowMount(DashboardsDropdown, {
      propsData: {
        ...props,
        defaultBranch,
      },
      ...storeOpts,
      ...opts,
    });
  }

  const findItems = () => wrapper.findAll(GlDropdownItem);
  const findItemAt = (i) => wrapper.findAll(GlDropdownItem).at(i);
  const findSearchInput = () => wrapper.find({ ref: 'monitorDashboardsDropdownSearch' });
  const findNoItemsMsg = () => wrapper.find({ ref: 'monitorDashboardsDropdownMsg' });
  const findStarredListDivider = () => wrapper.find({ ref: 'starredListDivider' });
  const setSearchTerm = (searchTerm) => wrapper.setData({ searchTerm });

  beforeEach(() => {
    mockDashboards = dashboardGitResponse;
    mockSelectedDashboard = null;
  });

  describe('when it receives dashboards data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays an item for each dashboard', () => {
      expect(findItems().length).toEqual(dashboardGitResponse.length);
    });

    it('displays items with the dashboard display name, with starred dashboards first', () => {
      expect(findItemAt(0).text()).toBe(starredDashboards[0].display_name);
      expect(findItemAt(1).text()).toBe(notStarredDashboards[0].display_name);
      expect(findItemAt(2).text()).toBe(notStarredDashboards[1].display_name);
    });

    it('displays separator between starred and not starred dashboards', () => {
      expect(findStarredListDivider().exists()).toBe(true);
    });

    it('displays a search input', () => {
      expect(findSearchInput().isVisible()).toBe(true);
    });

    it('hides no message text by default', () => {
      expect(findNoItemsMsg().isVisible()).toBe(false);
    });

    it('filters dropdown items when searched for item exists in the list', async () => {
      const searchTerm = 'Overview';
      setSearchTerm(searchTerm);
      await nextTick();

      expect(findItems()).toHaveLength(1);
    });

    it('shows no items found message when searched for item does not exists in the list', async () => {
      const searchTerm = 'does-not-exist';
      setSearchTerm(searchTerm);
      await nextTick();

      expect(findNoItemsMsg().isVisible()).toBe(true);
    });
  });

  describe('when a dashboard is selected', () => {
    beforeEach(() => {
      [mockSelectedDashboard] = starredDashboards;
      createComponent();
    });

    it('dashboard item is selected', () => {
      expect(findItemAt(0).props('isChecked')).toBe(true);
      expect(findItemAt(1).props('isChecked')).toBe(false);
    });
  });

  describe('when the dashboard is missing a display name', () => {
    beforeEach(() => {
      mockDashboards = dashboardGitResponse.map((d) => ({ ...d, display_name: undefined }));
      createComponent();
    });

    it('displays items with the dashboard path, with starred dashboards first', () => {
      expect(findItemAt(0).text()).toBe(starredDashboards[0].path);
      expect(findItemAt(1).text()).toBe(notStarredDashboards[0].path);
      expect(findItemAt(2).text()).toBe(notStarredDashboards[1].path);
    });
  });

  describe('when it receives starred dashboards', () => {
    beforeEach(() => {
      mockDashboards = starredDashboards;
      createComponent();
    });

    it('displays an item for each dashboard', () => {
      expect(findItems().length).toEqual(starredDashboards.length);
    });

    it('displays a star icon', () => {
      const star = findItemAt(0).find(GlIcon);
      expect(star.exists()).toBe(true);
      expect(star.attributes('name')).toBe('star');
    });

    it('displays no separator between starred and not starred dashboards', () => {
      expect(findStarredListDivider().exists()).toBe(false);
    });
  });

  describe('when it receives only not-starred dashboards', () => {
    beforeEach(() => {
      mockDashboards = notStarredDashboards;
      createComponent();
    });

    it('displays an item for each dashboard', () => {
      expect(findItems().length).toEqual(notStarredDashboards.length);
    });

    it('displays no star icon', () => {
      const star = findItemAt(0).find(GlIcon);
      expect(star.exists()).toBe(false);
    });

    it('displays no separator between starred and not starred dashboards', () => {
      expect(findStarredListDivider().exists()).toBe(false);
    });
  });

  describe('when a dashboard gets selected by the user', () => {
    beforeEach(() => {
      createComponent();
      findItemAt(1).vm.$emit('click');
    });

    it('emits a "selectDashboard" event', () => {
      expect(wrapper.emitted().selectDashboard).toBeTruthy();
    });
    it('emits a "selectDashboard" event with dashboard information', () => {
      expect(wrapper.emitted().selectDashboard[0]).toEqual([dashboardGitResponse[0]]);
    });
  });
});

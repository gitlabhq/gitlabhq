import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DashboardLayout from '~/vue_shared/components/customizable_dashboard/dashboard_layout.vue';
import GridstackWrapper from '~/vue_shared/components/customizable_dashboard/gridstack_wrapper.vue';

const dashboardConfig = {
  title: 'Dashboard title',
  description: 'This is my dashboard description',
  panels: [
    {
      id: '1',
      title: 'A dashboard panel',
      gridAttributes: {
        width: 6,
        height: 1,
        yPos: 0,
        xPos: 3,
      },
    },
  ],
};

describe('CustomizableDashboard', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findTitle = () => wrapper.findByTestId('title');
  const findDescription = () => wrapper.findByTestId('description');
  const findActionsContainer = () => wrapper.findByTestId('actions-container');
  const findFiltersContainer = () => wrapper.findByTestId('filters-container');
  const findGrid = () => wrapper.findComponent(GridstackWrapper);

  const panelSlotSpy = jest.fn();
  const emptyStateSlotSpy = jest.fn();

  const createWrapper = (props = {}, scopedSlots = {}) => {
    wrapper = shallowMountExtended(DashboardLayout, {
      propsData: {
        config: dashboardConfig,
        ...props,
      },
      scopedSlots: {
        panel: panelSlotSpy,
        'empty-state': emptyStateSlotSpy,
        ...scopedSlots,
      },
    });
  };

  afterEach(() => {
    panelSlotSpy.mockRestore();
    emptyStateSlotSpy.mockRestore();
  });

  describe('default behaviour', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the dashboard title', () => {
      expect(findTitle().text()).toContain('Dashboard title');
    });

    it('renders the dashboard description', () => {
      expect(findDescription().text()).toContain('This is my dashboard description');
    });

    it('renders the dashboard grid with the config', () => {
      expect(findGrid().props('value')).toMatchObject(dashboardConfig);
    });

    it('renders the panel slot for each panel', () => {
      expect(panelSlotSpy).toHaveBeenCalledTimes(dashboardConfig.panels.length);
    });

    it('does not render the empty state', () => {
      expect(emptyStateSlotSpy).not.toHaveBeenCalled();
    });

    it('does not render the filter or actions containers', () => {
      expect(findFiltersContainer().exists()).toBe(false);
      expect(findActionsContainer().exists()).toBe(false);
    });
  });

  describe('when a dashboard has no panels', () => {
    beforeEach(() => {
      createWrapper({
        config: {
          ...dashboardConfig,
          panels: undefined,
        },
      });
    });

    it('does not render the dashboard grid', () => {
      expect(findGrid().exists()).toBe(false);
    });

    it('renders the empty state', () => {
      expect(emptyStateSlotSpy).toHaveBeenCalled();
    });
  });

  describe('when a dashboard has no description', () => {
    beforeEach(() => {
      createWrapper({
        config: {
          ...dashboardConfig,
          description: undefined,
        },
      });
    });

    it('does not render the dashboard description', () => {
      expect(findDescription().exists()).toBe(false);
    });
  });

  describe('when a dashboard has title and description slots', () => {
    const titleSlotSpy = jest.fn();
    const descriptionSlotSpy = jest.fn();

    beforeEach(() => {
      createWrapper(
        {},
        {
          title() {
            titleSlotSpy();
            return this.$createElement('div');
          },
          description() {
            descriptionSlotSpy();
            return this.$createElement('div');
          },
        },
      );
    });

    afterEach(() => {
      titleSlotSpy.mockRestore();
      descriptionSlotSpy.mockRestore();
    });

    it('renders the title slot and not the config title', () => {
      expect(titleSlotSpy).toHaveBeenCalled();
      expect(findTitle().exists()).toBe(false);
    });

    it('renders the description slot and not the config description', () => {
      expect(descriptionSlotSpy).toHaveBeenCalled();
      expect(findDescription().exists()).toBe(false);
    });
  });

  describe('when a dashboard has actions slot content', () => {
    beforeEach(() => {
      createWrapper({}, { actions: '<div>actions</div>' });
    });

    it('renders the action slots', () => {
      expect(findActionsContainer().exists()).toBe(true);
    });
  });

  describe('when a dashboard has filters slot content', () => {
    beforeEach(() => {
      createWrapper({}, { filters: '<div>filters</div>' });
    });

    it('renders the filters container', () => {
      expect(findFiltersContainer().exists()).toBe(true);
    });
  });
});

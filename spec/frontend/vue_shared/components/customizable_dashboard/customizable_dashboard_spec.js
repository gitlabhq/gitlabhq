import { nextTick } from 'vue';
import { RouterLinkStub } from '@vue/test-utils';
import { GlLink, GlSprintf, GlExperimentBadge } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { mockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CustomizableDashboard from '~/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import GridstackWrapper from '~/vue_shared/components/customizable_dashboard/gridstack_wrapper.vue';
import AnonUsersFilter from '~/vue_shared/components/customizable_dashboard/filters/anon_users_filter.vue';
import DateRangeFilter from '~/vue_shared/components/customizable_dashboard/filters/date_range_filter.vue';
import waitForPromises from 'helpers/wait_for_promises';
import AvailableVisualizationsDrawer from '~/vue_shared/components/customizable_dashboard/dashboard_editor/available_visualizations_drawer.vue';
import {
  filtersToQueryParams,
  buildDefaultDashboardFilters,
} from '~/vue_shared/components/customizable_dashboard/utils';
import UrlSync, { HISTORY_REPLACE_UPDATE_METHOD } from '~/vue_shared/components/url_sync.vue';
import {
  CUSTOM_VALUE_STREAM_DASHBOARD,
  EVENT_LABEL_VIEWED_DASHBOARD_DESIGNER,
  EVENT_LABEL_EXCLUDE_ANONYMISED_USERS,
  DASHBOARD_SCHEMA_VERSION,
} from '~/vue_shared/components/customizable_dashboard/constants';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { stubComponent } from 'helpers/stub_component';
import {
  dashboard,
  builtinDashboard,
  betaDashboard,
  mockDateRangeFilterChangePayload,
  TEST_VISUALIZATION,
  TEST_EMPTY_DASHBOARD_SVG_PATH,
} from './mock_data';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

const NEW_DASHBOARD = () => ({
  title: '',
  version: DASHBOARD_SCHEMA_VERSION,
  description: '',
  panels: [],
  userDefined: true,
  status: null,
  errors: null,
});

describe('CustomizableDashboard', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;
  let trackingSpy;

  const $router = {
    push: jest.fn(),
  };

  const panelSlotSpy = jest.fn();
  const scopedSlots = {
    panel: panelSlotSpy,
  };

  const createWrapper = (
    props = {},
    loadedDashboard = dashboard,
    provide = {},
    routeParams = {},
    // eslint-disable-next-line max-params
  ) => {
    const loadDashboard = { ...loadedDashboard };

    wrapper = shallowMountExtended(CustomizableDashboard, {
      propsData: {
        initialDashboard: loadDashboard,
        availableVisualizations: {
          loading: true,
          hasError: false,
          visualizations: [],
        },
        ...props,
      },
      stubs: {
        AnonUsersFilter,
        RouterLink: RouterLinkStub,
        GlSprintf,
        DateRangeFilter,
        GridstackWrapper: stubComponent(GridstackWrapper, {
          props: ['value', 'editing'],
          template: `<div data-testid="gridstack-wrapper">
              <template v-for="panel in value.panels">
                <slot name="panel" v-bind="{ panel }"></slot>
              </template>
          </div>`,
        }),
      },
      mocks: {
        $router,
        $route: {
          params: routeParams,
        },
      },
      scopedSlots,
      provide: {
        dashboardEmptyStateIllustrationPath: TEST_EMPTY_DASHBOARD_SVG_PATH,
        ...provide,
      },
    });
  };

  const findDashboardTitle = () => wrapper.findByTestId('dashboard-title');
  const findEditModeTitle = () => wrapper.findByTestId('edit-mode-title');
  const findEditButton = () => wrapper.findByTestId('dashboard-edit-btn');
  const findAddVisualizationButton = () => wrapper.findByTestId('add-visualization-button');
  const findTitleInput = () => wrapper.findByTestId('dashboard-title-input');
  const findTitleFormGroup = () => wrapper.findByTestId('dashboard-title-form-group');
  const findDescriptionInput = () => wrapper.findByTestId('dashboard-description-input');
  const findSaveButton = () => wrapper.findByTestId('dashboard-save-btn');
  const findCancelButton = () => wrapper.findByTestId('dashboard-cancel-edit-btn');
  const findFilters = () => wrapper.findByTestId('dashboard-filters');
  const findAnonUsersFilter = () => wrapper.findComponent(AnonUsersFilter);
  const findDateRangeFilter = () => wrapper.findComponent(DateRangeFilter);
  const findUrlSync = () => wrapper.findComponent(UrlSync);
  const findVisualizationDrawer = () => wrapper.findComponent(AvailableVisualizationsDrawer);
  const findDashboardDescription = () => wrapper.findByTestId('dashboard-description');
  const findGridstackWrapper = () => wrapper.findComponent(GridstackWrapper);
  const findExperimentBadge = () => wrapper.findComponent(GlExperimentBadge);

  const enterDashboardTitle = async (title, titleValidationError = '') => {
    await findTitleInput().vm.$emit('input', title);
    await wrapper.setProps({ titleValidationError });
  };

  const enterDashboardDescription = async (description) => {
    await findDescriptionInput().vm.$emit('input', description);
  };

  const addDashboardPanels = async (currentDashboard, panels) => {
    await findGridstackWrapper().vm.$emit('input', {
      ...currentDashboard,
      panels,
    });
  };

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, window.document, jest.spyOn);
  });

  afterEach(() => {
    panelSlotSpy.mockRestore();
  });

  describe('when mounted updates', () => {
    let wrapperLimited;

    beforeEach(() => {
      wrapperLimited = document.createElement('div');
      wrapperLimited.classList.add('container-fluid', 'container-limited');
      document.body.appendChild(wrapperLimited);

      createWrapper();
    });

    afterEach(() => {
      document.body.removeChild(wrapperLimited);
    });

    it('body container', () => {
      expect(document.querySelectorAll('.container-fluid.not-container-limited').length).toBe(1);
    });

    it('body container after destroy', () => {
      wrapper.destroy();

      expect(document.querySelectorAll('.container-fluid.not-container-limited').length).toBe(0);
      expect(document.querySelectorAll('.container-fluid.container-limited').length).toBe(1);
    });
  });

  describe('default behaviour', () => {
    beforeEach(() => {
      createWrapper({}, dashboard);
    });

    it('shows the gridstack wrapper', () => {
      expect(findGridstackWrapper().props()).toMatchObject({
        value: dashboard,
        editing: false,
      });
    });

    it('shows the dashboard title', () => {
      expect(findDashboardTitle().text()).toBe('Analytics Overview');
    });

    it('shows the dashboard description', () => {
      expect(findDashboardDescription().text()).toBe('This is a dashboard');
    });

    it('does not show the edit mode page title', () => {
      expect(findEditModeTitle().exists()).toBe(false);
    });

    it('does not show the "cancel" button', () => {
      expect(findCancelButton().exists()).toBe(false);
    });

    it('does not show the title input', () => {
      expect(findTitleInput().exists()).toBe(false);
    });

    it('does not show the description input', () => {
      expect(findDescriptionInput().exists()).toBe(false);
    });

    it('does not show the filters', () => {
      expect(findFilters().exists()).toBe(false);
    });

    it('does not sync filters with the URL', () => {
      expect(findUrlSync().exists()).toBe(false);
    });

    it('does not show a dashboard documentation link', () => {
      expect(findDashboardDescription().findComponent(GlLink).exists()).toBe(false);
    });

    it('does not render the `Beta` badge', () => {
      expect(findExperimentBadge().exists()).toBe(false);
    });
  });

  describe('when a dashboard has no description', () => {
    beforeEach(() => {
      createWrapper({}, { ...dashboard, description: undefined });
    });

    it('does not show the dashboard description', () => {
      expect(findDashboardDescription().exists()).toBe(false);
    });
  });

  describe('when the slug is "value_stream_dashboard"', () => {
    beforeEach(() => {
      createWrapper({}, { ...builtinDashboard, slug: 'value_streams_dashboard' });
    });

    it('shows a "Learn more" link to the VSD user docs', () => {
      const link = findDashboardDescription().findComponent(GlLink);

      expect(link.text()).toBe('Learn more');
      expect(link.attributes('href')).toBe('/help/user/analytics/value_streams_dashboard');
    });
  });

  describe('when the slug is "ai_impact"', () => {
    beforeEach(() => {
      createWrapper({}, { ...builtinDashboard, slug: 'ai_impact' });
    });

    it('shows an alternative dashboard description', () => {
      expect(findDashboardDescription().text()).toBe(
        'Visualize the relation between AI usage and SDLC trends. Learn more about AI Impact analytics and GitLab Duo Pro seats usage.',
      );
    });

    it('shows a link to the docs page', () => {
      const link = findDashboardDescription().findAllComponents(GlLink).at(0);

      expect(link.text()).toBe('AI Impact analytics');
      expect(link.attributes('href')).toBe('/help/user/analytics/ai_impact_analytics');
    });

    it('shows a link to the Duo Pro subscription add-ons page', () => {
      const link = findDashboardDescription().findAllComponents(GlLink).at(1);

      expect(link.text()).toBe('GitLab Duo Pro seats usage');
      expect(link.attributes('href')).toBe(
        '/help/subscriptions/subscription-add-ons#assign-gitlab-duo-seats',
      );
    });
  });

  describe('when a dashboard is custom', () => {
    beforeEach(() => {
      createWrapper({}, dashboard);
    });

    it('shows the "edit" button', () => {
      expect(findEditButton().exists()).toBe(true);
    });
  });

  describe('when a dashboard is built-in', () => {
    beforeEach(() => {
      createWrapper({}, builtinDashboard);
    });

    it('does not show the "edit" button', () => {
      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('when a dashboard is a custom VSD', () => {
    const customVsd = { ...dashboard, slug: CUSTOM_VALUE_STREAM_DASHBOARD };

    it('does not show the "edit" button when `enable_vsd_visual_editor` is disabled', () => {
      createWrapper({}, customVsd);
      expect(findEditButton().exists()).toBe(false);
    });

    it('shows the "edit" button when `enable_vsd_visual_editor` is enabled', () => {
      const provide = { glFeatures: { enableVsdVisualEditor: true } };
      createWrapper({}, customVsd, provide);
      expect(findEditButton().exists()).toBe(true);
    });
  });

  describe('when a dashboard is in beta', () => {
    beforeEach(() => {
      createWrapper({}, betaDashboard);
    });

    it('renders the `Beta` badge', () => {
      expect(findExperimentBadge().props().type).toBe('beta');
    });
  });

  describe('when mounted with the $route.editing param', () => {
    beforeEach(() => {
      createWrapper({}, dashboard, {}, { editing: true });
    });

    it('render the visualization drawer in edit mode', () => {
      expect(findVisualizationDrawer().exists()).toBe(true);
    });
  });

  describe('when editing a custom dashboard', () => {
    let windowDialogSpy;
    let beforeUnloadEvent;

    beforeEach(async () => {
      beforeUnloadEvent = new Event('beforeunload');
      windowDialogSpy = jest.spyOn(beforeUnloadEvent, 'returnValue', 'set');

      createWrapper({}, dashboard);

      await waitForPromises();

      findEditButton().vm.$emit('click');
    });

    afterEach(() => {
      windowDialogSpy.mockRestore();
    });

    it(`tracks the "${EVENT_LABEL_VIEWED_DASHBOARD_DESIGNER}" event`, () => {
      expect(trackingSpy).toHaveBeenCalledWith(
        undefined,
        EVENT_LABEL_VIEWED_DASHBOARD_DESIGNER,
        expect.any(Object),
      );
    });

    it('passes the editing state to the gridstack-wrapper', () => {
      expect(findGridstackWrapper().props('editing')).toBe(true);
    });

    it('passes the editing state to the panels', () => {
      expect(panelSlotSpy).toHaveBeenCalledWith(expect.objectContaining({ editing: true }));
    });

    it('shows the edit mode page title', () => {
      expect(findEditModeTitle().text()).toBe('Edit your dashboard');
    });

    it('does not show the dashboard title header', () => {
      expect(findDashboardTitle().exists()).toBe(false);
    });

    it('shows the Save button', () => {
      expect(findSaveButton().props('loading')).toBe(false);
    });

    it('shows an input element with the title as value', () => {
      expect(findTitleInput().attributes()).toMatchObject({
        value: 'Analytics Overview',
        required: '',
      });
    });

    it('shows an input element with the description as value', () => {
      expect(findDescriptionInput().attributes('value')).toBe('This is a dashboard');
    });

    it('emits an event when title is edited', async () => {
      await enterDashboardTitle('New Title');

      expect(wrapper.emitted('title-input')[0]).toContain('New Title');
    });

    it('saves the dashboard changes when the "save" button is clicked', async () => {
      await enterDashboardTitle('New Title');

      await findSaveButton().vm.$emit('click');

      expect(wrapper.emitted('save')).toMatchObject([
        [
          'analytics_overview',
          {
            ...dashboard,
            title: 'New Title',
          },
        ],
      ]);
    });

    it('shows the "cancel" button', () => {
      expect(findCancelButton().exists()).toBe(true);
    });

    describe('and the "cancel" button is clicked with no changes made', () => {
      afterEach(() => {
        confirmAction.mockReset();
      });

      beforeEach(() => {
        confirmAction.mockReturnValue(new Promise(() => {}));

        return findCancelButton().vm.$emit('click');
      });

      it('does not show the confirm dialog', () => {
        expect(confirmAction).not.toHaveBeenCalled();
      });

      it('disables the edit state', () => {
        expect(findEditModeTitle().exists()).toBe(false);
      });

      it('sets "editing" to false on the gridstack wrapper', () => {
        expect(findGridstackWrapper().props('editing')).toBe(false);
      });
    });

    it('does not show the confirmation dialog when the "beforeunload" is emitted', () => {
      window.dispatchEvent(beforeUnloadEvent);

      expect(windowDialogSpy).not.toHaveBeenCalled();
    });

    describe('and changes were made', () => {
      beforeEach(() => {
        return findGridstackWrapper().vm.$emit('input', {
          ...dashboard,
          title: 'new title',
        });
      });

      it('shows the browser confirmation dialog when the "beforeunload" is emitted', () => {
        window.dispatchEvent(beforeUnloadEvent);

        expect(windowDialogSpy).toHaveBeenCalledWith(
          'Are you sure you want to lose unsaved changes?',
        );
      });

      describe('and the "cancel" button is clicked', () => {
        afterEach(() => {
          confirmAction.mockReset();
        });

        it('shows the confirm modal', async () => {
          confirmAction.mockReturnValue(new Promise(() => {}));

          await findCancelButton().vm.$emit('click');

          expect(confirmAction).toHaveBeenCalledWith(
            'Are you sure you want to cancel editing this dashboard?',
            {
              cancelBtnText: 'Continue editing',
              primaryBtnText: 'Discard changes',
            },
          );
        });
      });
    });

    it('does not show the "edit" button', () => {
      expect(findEditButton().exists()).toBe(false);
    });

    describe('with the visualization drawer', () => {
      it('renders the closed visualization drawer', () => {
        expect(findVisualizationDrawer().props()).toMatchObject({
          visualizations: {},
          loading: true,
          open: false,
        });
      });

      describe('and the user clicks on the "Add visualization" button', () => {
        beforeEach(() => {
          return findAddVisualizationButton().trigger('click');
        });

        it('opens the drawer', () => {
          expect(findVisualizationDrawer().props('open')).toBe(true);
        });

        it('closes the drawer when the user clicks on the same button again', async () => {
          await findAddVisualizationButton().trigger('click');

          expect(findVisualizationDrawer().props('open')).toBe(false);
        });
      });

      describe('and the drawer emits a close event', () => {
        beforeEach(async () => {
          await findVisualizationDrawer().vm.$emit('close');
        });

        it('closes the drawer', () => {
          expect(findVisualizationDrawer().props('open')).toBe(false);
        });
      });

      describe('and the drawer emits a selected event', () => {
        beforeEach(async () => {
          await findAddVisualizationButton().trigger('click');
          await findVisualizationDrawer().vm.$emit('select', [TEST_VISUALIZATION()]);
        });

        it('closes the drawer', () => {
          expect(findVisualizationDrawer().props('open')).toBe(false);
        });

        it('adds new panels to the dashboard', () => {
          const { panels } = findGridstackWrapper().props().value;

          expect(panels).toHaveLength(3);
          expect(panels[2]).toMatchObject({
            id: expect.stringContaining('panel-'),
            title: 'Test visualization',
            gridAttributes: { width: 4, height: 3 },
            queryOverrides: {},
            options: {},
            visualization: {
              version: 1,
              type: 'LineChart',
              slug: 'test_visualization',
              data: { type: 'cube_analytics', query: expect.any(Object) },
              errors: null,
            },
          });
        });
      });
    });

    describe('and a panel is deleted', () => {
      const removePanel = dashboard.panels[0];

      beforeEach(() => {
        const mockPanel = panelSlotSpy.mock.calls[0].find(
          ({ panel }) => panel.id === removePanel.id,
        );
        mockPanel.deletePanel();
      });

      it('removes the chosen panel from the dashboard', () => {
        const { panels } = findGridstackWrapper().props().value;
        const panelIds = panels.map(({ id }) => id);

        expect(panels).toHaveLength(1);
        expect(panelIds).not.toContain(removePanel.id);
      });
    });
  });

  describe('dashboard filters', () => {
    const defaultFilters = buildDefaultDashboardFilters('');

    describe('when showDateRangeFilter is false', () => {
      beforeEach(() => {
        createWrapper({
          showDateRangeFilter: false,
          syncUrlFilters: true,
          defaultFilters,
          dateRangeLimit: 0,
        });
      });

      it('does not show the filters', () => {
        expect(findDateRangeFilter().exists()).toBe(false);
        expect(findAnonUsersFilter().exists()).toBe(false);
      });
    });

    describe('when the date range filter is enabled and configured', () => {
      describe('by default', () => {
        beforeEach(() => {
          createWrapper({ showDateRangeFilter: true, syncUrlFilters: true, defaultFilters });
        });

        it('does not show the anon users filter', () => {
          expect(findAnonUsersFilter().exists()).toBe(false);
        });

        it('shows the date range filter and passes the default options and filters', () => {
          expect(findDateRangeFilter().props()).toMatchObject({
            startDate: defaultFilters.startDate,
            endDate: defaultFilters.endDate,
            defaultOption: defaultFilters.dateRangeOption,
            dateRangeLimit: 0,
          });
        });

        it('synchronizes the filters with the URL', () => {
          expect(findUrlSync().props()).toMatchObject({
            historyUpdateMethod: HISTORY_REPLACE_UPDATE_METHOD,
            query: filtersToQueryParams(defaultFilters),
          });
        });

        it('sets the panel filters to the default date range', () => {
          expect(panelSlotSpy).toHaveBeenCalledWith(
            expect.objectContaining({ filters: expect.objectContaining(defaultFilters) }),
          );
        });

        it('updates the panel filters when the date range is changed', async () => {
          await findDateRangeFilter().vm.$emit('change', mockDateRangeFilterChangePayload);

          expect(panelSlotSpy).toHaveBeenCalledWith(
            expect.objectContaining({
              filters: expect.objectContaining(mockDateRangeFilterChangePayload),
            }),
          );
        });
      });

      describe.each([0, 12, 31])('when given a date range limit of %d', (dateRangeLimit) => {
        beforeEach(() => {
          createWrapper({
            showDateRangeFilter: true,
            syncUrlFilters: true,
            defaultFilters,
            dateRangeLimit,
          });
        });

        it('passes the date range limit to the date range filter', () => {
          expect(findDateRangeFilter().props()).toMatchObject({
            dateRangeLimit,
          });
        });
      });
    });

    describe('filtering anonymous users', () => {
      beforeEach(() => {
        createWrapper({
          showAnonUsersFilter: true,
          syncUrlFilters: true,
          defaultFilters,
          dateRangeLimit: 0,
        });
      });

      it('does not show the date range filter', () => {
        expect(findDateRangeFilter().exists()).toBe(false);
      });

      it('sets the default filter on the anon users filter component', () => {
        expect(findAnonUsersFilter().props('value')).toBe(defaultFilters.filterAnonUsers);
      });

      it('updates the panel filters when anon users are filtered out', async () => {
        expect(panelSlotSpy).toHaveBeenCalledWith(
          expect.objectContaining({ filters: expect.objectContaining({ filterAnonUsers: false }) }),
        );

        await findAnonUsersFilter().vm.$emit('change', true);

        expect(panelSlotSpy).toHaveBeenCalledWith(
          expect.objectContaining({ filters: expect.objectContaining({ filterAnonUsers: true }) }),
        );
      });

      it(`tracks the "${EVENT_LABEL_EXCLUDE_ANONYMISED_USERS}" event when excluding anon users`, async () => {
        await findAnonUsersFilter().vm.$emit('change', true);

        expect(trackingSpy).toHaveBeenCalledWith(
          undefined,
          EVENT_LABEL_EXCLUDE_ANONYMISED_USERS,
          expect.any(Object),
        );
      });

      it(`does not track "${EVENT_LABEL_EXCLUDE_ANONYMISED_USERS}" event including anon users`, async () => {
        await findAnonUsersFilter().vm.$emit('change', false);

        expect(trackingSpy).not.toHaveBeenCalled();
      });
    });
  });

  describe('when a dashboard is new and the editing feature flag is enabled', () => {
    const newDashboard = NEW_DASHBOARD();
    const newPanels = [dashboard.panels[0]];

    beforeEach(() => {
      createWrapper(
        {
          isNewDashboard: true,
        },
        newDashboard,
      );
    });

    it(`tracks the "${EVENT_LABEL_VIEWED_DASHBOARD_DESIGNER}" event`, () => {
      expect(trackingSpy).toHaveBeenCalledWith(
        undefined,
        EVENT_LABEL_VIEWED_DASHBOARD_DESIGNER,
        expect.any(Object),
      );
    });

    it('routes to the dashboard listing page when "cancel" is clicked', async () => {
      await findCancelButton().vm.$emit('click');

      expect($router.push).toHaveBeenCalledWith('/');
    });

    describe('and the "cancel" button is clicked with changes made', () => {
      afterEach(() => {
        confirmAction.mockReset();
      });

      beforeEach(() => {
        confirmAction.mockResolvedValue(true);

        return findGridstackWrapper().vm.$emit('input', {
          ...newDashboard,
          title: 'new title',
        });
      });

      it('shows a confirmation modal for new dashboards', async () => {
        await findCancelButton().vm.$emit('click');

        expect(confirmAction).toHaveBeenCalledWith(
          'Are you sure you want to cancel creating this dashboard?',
          {
            cancelBtnText: 'Continue creating',
            primaryBtnText: 'Discard changes',
          },
        );
      });

      it('routes to the dashboard listing if the user confirms', async () => {
        confirmAction.mockResolvedValue(true);

        await findCancelButton().vm.$emit('click');
        await waitForPromises();

        expect($router.push).toHaveBeenCalledWith('/');
      });

      it('does not route to the dashboard listing if the user opts to continue editing', async () => {
        confirmAction.mockResolvedValue(false);

        await findCancelButton().vm.$emit('click');
        await waitForPromises();

        expect($router.push).not.toHaveBeenCalled();
      });
    });

    it('shows the new dashboard page title', () => {
      expect(findEditModeTitle().text()).toBe('Create your dashboard');
    });

    it('shows the "Add visualization" button', () => {
      expect(findAddVisualizationButton().text()).toBe('Add visualization');
    });

    it('does not show the filters', () => {
      expect(findDateRangeFilter().exists()).toBe(false);
      expect(findAnonUsersFilter().exists()).toBe(false);
    });

    describe('when saving', () => {
      describe('and there is no title nor panels', () => {
        beforeEach(async () => {
          findTitleInput().element.focus = jest.fn();

          await findSaveButton().vm.$emit('click');
          await wrapper.setProps({ titleValidationError: 'This field is required.' });
        });

        it('does not save the dashboard', () => {
          expect(wrapper.emitted('save')).toBeUndefined();
        });

        it('shows the invalid state on the title input', () => {
          expect(findTitleFormGroup().attributes('state')).toBe(undefined);
          expect(findTitleFormGroup().attributes('invalid-feedback')).toBe(
            'This field is required.',
          );

          expect(findTitleInput().attributes('state')).toBe(undefined);
        });

        it('sets focus on the dashboard title input', () => {
          expect(findTitleInput().element.focus).toHaveBeenCalled();
        });

        describe('and a user then inputs a title', () => {
          beforeEach(async () => {
            await enterDashboardTitle('New Title');
          });

          it('shows title input as valid', () => {
            expect(findTitleFormGroup().attributes('state')).toBe('true');
            expect(findTitleInput().attributes('state')).toBe('true');
          });
        });
      });

      describe('and there is a title but no panels', () => {
        beforeEach(async () => {
          await enterDashboardTitle('New Title');
          await findSaveButton().vm.$emit('click');
        });

        it('does not save the dashboard', () => {
          expect(wrapper.emitted('save')).toBeUndefined();
        });

        it('shows an alert', () => {
          expect(createAlert).toHaveBeenCalledWith({ message: 'Add a visualization' });
        });

        describe('and the component is destroyed', () => {
          beforeEach(() => {
            wrapper.destroy();

            return nextTick();
          });

          it('dismisses the alert', () => {
            expect(mockAlertDismiss).toHaveBeenCalled();
          });
        });

        describe('and saved is clicked after a panel has been added', () => {
          beforeEach(async () => {
            await addDashboardPanels(newDashboard, newPanels);

            await findSaveButton().vm.$emit('click');
          });

          it('dismisses the alert', () => {
            expect(mockAlertDismiss).toHaveBeenCalled();
          });
        });
      });

      describe('and the dashboard has a title and panels', () => {
        beforeEach(async () => {
          await addDashboardPanels(newDashboard, newPanels);

          await enterDashboardTitle('New Title');
        });

        it('shows title input as valid', async () => {
          await findSaveButton().vm.$emit('click');

          expect(findTitleFormGroup().attributes('state')).toBe('true');
          expect(findTitleInput().attributes('state')).toBe('true');
        });

        it('does not show an alert', async () => {
          await findSaveButton().vm.$emit('click');

          expect(mockAlertDismiss).not.toHaveBeenCalled();
        });

        it('saves the dashboard with a new a slug', async () => {
          await findSaveButton().vm.$emit('click');

          expect(wrapper.emitted('save')).toStrictEqual([
            [
              'new_title',
              {
                slug: 'new_title',
                version: DASHBOARD_SCHEMA_VERSION,
                title: 'New Title',
                description: '',
                panels: newPanels,
                userDefined: true,
                status: null,
                errors: null,
              },
            ],
          ]);
        });

        describe('and a description is added', () => {
          beforeEach(async () => {
            await enterDashboardDescription('New description');
          });

          it('saves the dashboard with a new description', async () => {
            await findSaveButton().vm.$emit('click');

            expect(wrapper.emitted('save')[0][1]).toMatchObject({
              description: 'New description',
            });
          });
        });
      });
    });
  });

  describe('when saving while editing and the editor is enabled', () => {
    beforeEach(() => {
      createWrapper({ isSaving: true }, dashboard);

      findEditButton().vm.$emit('click');
    });

    it('shows the Save button as loading', () => {
      expect(findSaveButton().props('loading')).toBe(true);
    });
  });

  describe('changes saved', () => {
    it.each`
      editing  | changesSaved | newState
      ${true}  | ${true}      | ${false}
      ${true}  | ${false}     | ${true}
      ${false} | ${true}      | ${false}
      ${false} | ${false}     | ${false}
    `(
      'when editing="$editing" and changesSaved="$changesSaved" the new editing state is "$newState',
      async ({ editing, changesSaved, newState }) => {
        createWrapper({ changesSaved, isNewDashboard: editing }, dashboard);

        await nextTick();

        expect(findEditModeTitle().exists()).toBe(newState);
      },
    );
  });

  describe('when editing a custom dashboard with no panels', () => {
    const dashboardWithoutPanels = {
      ...dashboard,
      panels: [],
    };

    beforeEach(() => {
      createWrapper({}, dashboardWithoutPanels);

      return findEditButton().vm.$emit('click');
    });

    it('does not validate the presence of panels when saving', async () => {
      await findSaveButton().vm.$emit('click');

      expect(createAlert).not.toHaveBeenCalled();

      expect(wrapper.emitted('save')).toStrictEqual([
        [dashboardWithoutPanels.slug, dashboardWithoutPanels],
      ]);
    });
  });

  // TODO: Move this along with all the dialog logic to analytics dashboard.
  // This is planned as part of the larger refactor to simplify this component.
  // https://gitlab.com/gitlab-org/gitlab/-/issues/426550
  describe('confirmDiscardIfChanged', () => {
    beforeAll(() => {
      confirmAction.mockResolvedValue(false);
    });

    afterAll(() => {
      confirmAction.mockReset();
    });

    describe.each`
      isSaving | changesMade | expected
      ${true}  | ${true}     | ${true}
      ${false} | ${true}     | ${false}
      ${true}  | ${false}    | ${true}
      ${false} | ${false}    | ${true}
    `(
      'when isSaving=$isSaving and changesMade=$changesMade',
      ({ isSaving, changesMade, expected }) => {
        beforeEach(async () => {
          createWrapper({ isSaving }, dashboard);

          await findEditButton().vm.$emit('click');

          if (changesMade) await enterDashboardTitle('New Title');
        });

        it(`it returns ${expected}`, async () => {
          // This only gets called from AnalyticsDashboard so we need to test
          // the method directly here since it's not called in the component.
          expect(await wrapper.vm.confirmDiscardIfChanged()).toBe(expected);
        });
      },
    );
  });
});

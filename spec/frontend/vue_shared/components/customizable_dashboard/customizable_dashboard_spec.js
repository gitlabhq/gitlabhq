import { nextTick } from 'vue';
import { RouterLinkStub } from '@vue/test-utils';
import { GlLink, GlSprintf, GlExperimentBadge } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { mockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CustomizableDashboard from '~/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import GridstackWrapper from '~/vue_shared/components/customizable_dashboard/gridstack_wrapper.vue';
import waitForPromises from 'helpers/wait_for_promises';
import AvailableVisualizationsDrawer from '~/vue_shared/components/customizable_dashboard/dashboard_editor/available_visualizations_drawer.vue';
import {
  EVENT_LABEL_VIEWED_DASHBOARD_DESIGNER,
  DASHBOARD_SCHEMA_VERSION,
} from '~/vue_shared/components/customizable_dashboard/constants';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { stubComponent } from 'helpers/stub_component';
import { trimText } from 'helpers/text_helper';
import {
  dashboard,
  betaDashboard,
  createVisualization,
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
  const defaultSlots = {
    panel: panelSlotSpy,
  };

  const createWrapper = (
    props = {},
    { loadedDashboard = dashboard, provide = {}, routeParams = {}, scopedSlots = {} } = {},
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
        RouterLink: RouterLinkStub,
        GlSprintf,
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
      scopedSlots: {
        ...defaultSlots,
        ...scopedSlots,
      },
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
      createWrapper();
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

    it('does not show a dashboard documentation link', () => {
      expect(findDashboardDescription().findComponent(GlLink).exists()).toBe(false);
    });

    it('does not render the `Beta` badge', () => {
      expect(findExperimentBadge().exists()).toBe(false);
    });
  });

  describe('when a dashboard has no description', () => {
    beforeEach(() => {
      createWrapper({}, { loadedDashboard: { ...dashboard, description: undefined } });
    });

    it('does not show the dashboard description', () => {
      expect(findDashboardDescription().exists()).toBe(false);
    });
  });

  describe('when a dashboard has an after-description slot', () => {
    beforeEach(() => {
      createWrapper(
        {},
        {
          scopedSlots: {
            'after-description': `<p>After description</p>`,
          },
        },
      );
    });

    it('does render after-description slot after the description', () => {
      expect(trimText(findDashboardDescription().text())).toEqual(
        'This is a dashboard After description',
      );
    });
  });

  describe('editingEnabled', () => {
    it('shows the edit button if editingEnabled', () => {
      createWrapper({ editingEnabled: true });

      expect(findEditButton().exists()).toBe(true);
    });

    it('does not show the edit button if not editingEnabled', () => {
      createWrapper({ editingEnabled: false });

      expect(findEditButton().exists()).toBe(false);
    });

    it('shows the edit button by default', () => {
      createWrapper();

      expect(findEditButton().exists()).toBe(true);
    });
  });

  describe('when a dashboard is in beta', () => {
    beforeEach(() => {
      createWrapper({}, { loadedDashboard: betaDashboard });
    });

    it('renders the `Beta` badge', () => {
      expect(findExperimentBadge().props().type).toBe('beta');
    });
  });

  describe('when mounted with the $route.editing param', () => {
    beforeEach(() => {
      createWrapper({}, { routeParams: { editing: true } });
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

      createWrapper();

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
      expect(findTitleInput().props()).toMatchObject({
        value: 'Analytics Overview',
        required: true,
      });
    });

    it('shows an input element with the description as value', () => {
      expect(findDescriptionInput().props('value')).toBe('This is a dashboard');
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
          await findVisualizationDrawer().vm.$emit('select', [createVisualization()]);
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
    describe('default behavior', () => {
      beforeEach(() => {
        createWrapper(
          {},
          { scopedSlots: { filters: '<p data-testid="test-filters">Filters here</p>' } },
        );
      });

      it('renders the filters slot', () => {
        expect(findFilters().exists()).toBe(true);
        expect(wrapper.findByTestId('test-filters').exists()).toBe(true);
      });

      it('does not render the filters slot when in editing mode', async () => {
        findEditButton().vm.$emit('click');

        await waitForPromises();

        expect(findFilters().exists()).toBe(false);
      });
    });

    it('does not render the filters slot if isNewDashboard=true', () => {
      createWrapper(
        { isNewDashboard: true },
        { scopedSlots: { filters: '<p data-testid="test-filters">Filters here</p>' } },
      );

      expect(findFilters().exists()).toBe(false);
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
        { loadedDashboard: newDashboard },
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
      createWrapper({ isSaving: true });

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
        createWrapper({ changesSaved, isNewDashboard: editing });

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
      createWrapper({}, { loadedDashboard: dashboardWithoutPanels });

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
          createWrapper({ isSaving });

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

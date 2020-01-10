import { shallowMount, createLocalVue, mount } from '@vue/test-utils';
import { GlDropdownItem, GlButton, GlToast } from '@gitlab/ui';
import VueDraggable from 'vuedraggable';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import statusCodes from '~/lib/utils/http_status';
import { metricStates } from '~/monitoring/constants';
import Dashboard from '~/monitoring/components/dashboard.vue';
import DateTimePicker from '~/monitoring/components/date_time_picker/date_time_picker.vue';
import GroupEmptyState from '~/monitoring/components/group_empty_state.vue';
import { createStore } from '~/monitoring/stores';
import * as types from '~/monitoring/stores/mutation_types';
import { setupComponentStore, propsData } from '../init_utils';
import {
  metricsGroupsAPIResponse,
  mockedQueryResultPayload,
  mockApiEndpoint,
  environmentData,
  dashboardGitResponse,
} from '../mock_data';

const localVue = createLocalVue();
const expectedPanelCount = 2;

describe('Dashboard', () => {
  let store;
  let wrapper;
  let mock;

  const createShallowWrapper = (props = {}, options = {}) => {
    wrapper = shallowMount(Dashboard, {
      localVue,
      propsData: { ...propsData, ...props },
      store,
      ...options,
    });
  };

  const createMountedWrapper = (props = {}, options = {}) => {
    wrapper = mount(Dashboard, {
      localVue,
      propsData: { ...propsData, ...props },
      store,
      ...options,
    });
  };

  beforeEach(() => {
    store = createStore();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
    mock.restore();
  });

  describe('no metrics are available yet', () => {
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(statusCodes.OK, metricsGroupsAPIResponse);

      createShallowWrapper({}, { attachToDocument: true });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('shows the environment selector', () => {
      expect(wrapper.vm.$el.querySelector('.js-environments-dropdown')).toBeTruthy();
    });
  });

  describe('no data found', () => {
    beforeEach(done => {
      mock.onGet(mockApiEndpoint).reply(statusCodes.OK, metricsGroupsAPIResponse);

      createShallowWrapper({}, { attachToDocument: true });

      wrapper.vm.$nextTick(done);
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('shows the environment selector dropdown', () => {
      expect(wrapper.vm.$el.querySelector('.js-environments-dropdown')).toBeTruthy();
    });
  });

  describe('request information to the server', () => {
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);
    });

    it('shows up a loading state', done => {
      createShallowWrapper({ hasMetrics: true }, { attachToDocument: true });

      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.vm.emptyState).toEqual('loading');

          done();
        })
        .catch(done.fail);
    });

    it('hides the group panels when showPanels is false', done => {
      createMountedWrapper(
        { hasMetrics: true, showPanels: false },
        { attachToDocument: true, stubs: ['graph-group', 'panel-type'] },
      );

      setupComponentStore(wrapper);

      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.vm.showEmptyState).toEqual(false);
          expect(wrapper.vm.$el.querySelector('.prometheus-panel')).toEqual(null);
          // TODO: The last expectation doesn't belong here, it belongs in a `group_group_spec.js` file
          // Issue: https://gitlab.com/gitlab-org/gitlab/issues/118780
          // expect(wrapper.vm.$el.querySelector('.prometheus-graph-group')).toBeTruthy();

          done();
        })
        .catch(done.fail);
    });

    it('fetches the metrics data with proper time window', done => {
      jest.spyOn(store, 'dispatch');

      createMountedWrapper(
        { hasMetrics: true },
        { attachToDocument: true, stubs: ['graph-group', 'panel-type'] },
      );

      wrapper.vm.$store.commit(
        `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
        environmentData,
      );

      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(store.dispatch).toHaveBeenCalled();

          done();
        })
        .catch(done.fail);
    });
  });

  describe('when all requests have been commited by the store', () => {
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(statusCodes.OK, metricsGroupsAPIResponse);

      createMountedWrapper(
        { hasMetrics: true },
        { attachToDocument: true, stubs: ['graph-group', 'panel-type'] },
      );

      setupComponentStore(wrapper);
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('renders the environments dropdown with a number of environments', done => {
      wrapper.vm
        .$nextTick()
        .then(() => {
          const environmentDropdownItems = wrapper
            .find('.js-environments-dropdown')
            .findAll(GlDropdownItem);

          expect(wrapper.vm.environments.length).toEqual(environmentData.length);
          expect(environmentDropdownItems.length).toEqual(wrapper.vm.environments.length);

          environmentDropdownItems.wrappers.forEach((itemWrapper, index) => {
            const anchorEl = itemWrapper.find('a');
            if (anchorEl.exists() && environmentData[index].metrics_path) {
              const href = anchorEl.attributes('href');
              expect(href).toBe(environmentData[index].metrics_path);
            }
          });

          done();
        })
        .catch(done.fail);
    });

    it('renders the environments dropdown with a single active element', done => {
      wrapper.vm
        .$nextTick()
        .then(() => {
          const environmentDropdownItems = wrapper
            .find('.js-environments-dropdown')
            .findAll(GlDropdownItem);
          const activeItem = environmentDropdownItems.wrappers.filter(itemWrapper =>
            itemWrapper.find('.active').exists(),
          );

          expect(activeItem.length).toBe(1);
          done();
        })
        .catch(done.fail);
    });
  });

  it('hides the environments dropdown list when there is no environments', done => {
    createMountedWrapper(
      { hasMetrics: true },
      { attachToDocument: true, stubs: ['graph-group', 'panel-type'] },
    );

    wrapper.vm.$store.commit(
      `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
      metricsGroupsAPIResponse,
    );
    wrapper.vm.$store.commit(
      `monitoringDashboard/${types.RECEIVE_METRIC_RESULT_SUCCESS}`,
      mockedQueryResultPayload,
    );

    wrapper.vm
      .$nextTick()
      .then(() => {
        const environmentDropdownItems = wrapper
          .find('.js-environments-dropdown')
          .findAll(GlDropdownItem);

        expect(environmentDropdownItems.length).toEqual(0);
        done();
      })
      .catch(done.fail);
  });

  it('renders the datetimepicker dropdown', done => {
    createMountedWrapper(
      { hasMetrics: true },
      { attachToDocument: true, stubs: ['graph-group', 'panel-type'] },
    );

    setupComponentStore(wrapper);

    wrapper.vm
      .$nextTick()
      .then(() => {
        expect(wrapper.find(DateTimePicker).exists()).toBe(true);
        done();
      })
      .catch(done.fail);
  });

  describe('when one of the metrics is missing', () => {
    beforeEach(done => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);

      createShallowWrapper({ hasMetrics: true }, { attachToDocument: true });
      setupComponentStore(wrapper);

      wrapper.vm.$nextTick(done);
    });

    it('shows a group empty area', () => {
      const emptyGroup = wrapper.findAll({ ref: 'empty-group' });

      expect(emptyGroup).toHaveLength(1);
      expect(emptyGroup.is(GroupEmptyState)).toBe(true);
    });

    it('group empty area displays a NO_DATA state', () => {
      expect(
        wrapper
          .findAll({ ref: 'empty-group' })
          .at(0)
          .props('selectedState'),
      ).toEqual(metricStates.NO_DATA);
    });
  });

  describe('drag and drop function', () => {
    const findDraggables = () => wrapper.findAll(VueDraggable);
    const findEnabledDraggables = () => findDraggables().filter(f => !f.attributes('disabled'));
    const findDraggablePanels = () => wrapper.findAll('.js-draggable-panel');
    const findRearrangeButton = () => wrapper.find('.js-rearrange-button');

    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(statusCodes.OK, metricsGroupsAPIResponse);
    });

    beforeEach(done => {
      createShallowWrapper({ hasMetrics: true }, { attachToDocument: true });

      setupComponentStore(wrapper);

      wrapper.vm.$nextTick(done);
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('wraps vuedraggable', () => {
      expect(findDraggablePanels().exists()).toBe(true);
      expect(findDraggablePanels().length).toEqual(expectedPanelCount);
    });

    it('is disabled by default', () => {
      expect(findRearrangeButton().exists()).toBe(false);
      expect(findEnabledDraggables().length).toBe(0);
    });

    describe('when rearrange is enabled', () => {
      beforeEach(done => {
        wrapper.setProps({ rearrangePanelsAvailable: true });
        wrapper.vm.$nextTick(done);
      });

      it('displays rearrange button', () => {
        expect(findRearrangeButton().exists()).toBe(true);
      });

      describe('when rearrange button is clicked', () => {
        const findFirstDraggableRemoveButton = () =>
          findDraggablePanels()
            .at(0)
            .find('.js-draggable-remove');

        beforeEach(done => {
          findRearrangeButton().vm.$emit('click');
          wrapper.vm.$nextTick(done);
        });

        it('it enables draggables', () => {
          expect(findRearrangeButton().attributes('pressed')).toBeTruthy();
          expect(findEnabledDraggables()).toEqual(findDraggables());
        });

        it('metrics can be swapped', done => {
          const firstDraggable = findDraggables().at(0);
          const mockMetrics = [...metricsGroupsAPIResponse[1].panels];

          const firstTitle = mockMetrics[0].title;
          const secondTitle = mockMetrics[1].title;

          // swap two elements and `input` them
          [mockMetrics[0], mockMetrics[1]] = [mockMetrics[1], mockMetrics[0]];
          firstDraggable.vm.$emit('input', mockMetrics);

          wrapper.vm.$nextTick(() => {
            const { panels } = wrapper.vm.dashboard.panel_groups[1];

            expect(panels[1].title).toEqual(firstTitle);
            expect(panels[0].title).toEqual(secondTitle);
            done();
          });
        });

        it('shows a remove button, which removes a panel', done => {
          expect(findFirstDraggableRemoveButton().isEmpty()).toBe(false);

          expect(findDraggablePanels().length).toEqual(expectedPanelCount);
          findFirstDraggableRemoveButton().trigger('click');

          wrapper.vm.$nextTick(() => {
            expect(findDraggablePanels().length).toEqual(expectedPanelCount - 1);
            done();
          });
        });

        it('it disables draggables when clicked again', done => {
          findRearrangeButton().vm.$emit('click');
          wrapper.vm.$nextTick(() => {
            expect(findRearrangeButton().attributes('pressed')).toBeFalsy();
            expect(findEnabledDraggables().length).toBe(0);
            done();
          });
        });
      });
    });
  });

  describe('cluster health', () => {
    beforeEach(done => {
      mock.onGet(propsData.metricsEndpoint).reply(statusCodes.OK, JSON.stringify({}));
      createShallowWrapper({ hasMetrics: true });

      // all_dashboards is not defined in health dashboards
      wrapper.vm.$store.commit(`monitoringDashboard/${types.SET_ALL_DASHBOARDS}`, undefined);
      wrapper.vm.$nextTick(done);
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('renders correctly', () => {
      expect(wrapper.isVueInstance()).toBe(true);
      expect(wrapper.exists()).toBe(true);
    });
  });

  describe('dashboard edit link', () => {
    const findEditLink = () => wrapper.find('.js-edit-link');

    beforeEach(done => {
      mock.onGet(mockApiEndpoint).reply(statusCodes.OK, metricsGroupsAPIResponse);

      createShallowWrapper({ hasMetrics: true }, { attachToDocument: true });

      wrapper.vm.$store.commit(
        `monitoringDashboard/${types.SET_ALL_DASHBOARDS}`,
        dashboardGitResponse,
      );
      wrapper.vm.$nextTick(done);
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('is not present for the default dashboard', () => {
      expect(findEditLink().exists()).toBe(false);
    });

    it('is present for a custom dashboard, and links to its edit_path', done => {
      const dashboard = dashboardGitResponse[1]; // non-default dashboard
      const currentDashboard = dashboard.path;

      wrapper.setProps({ currentDashboard });
      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(findEditLink().exists()).toBe(true);
          expect(findEditLink().attributes('href')).toBe(dashboard.project_blob_path);
          done();
        })
        .catch(done.fail);
    });
  });

  describe('Dashboard dropdown', () => {
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);

      createMountedWrapper(
        { hasMetrics: true },
        { attachToDocument: true, stubs: ['graph-group', 'panel-type'] },
      );

      wrapper.vm.$store.commit(
        `monitoringDashboard/${types.SET_ALL_DASHBOARDS}`,
        dashboardGitResponse,
      );
    });

    it('shows the dashboard dropdown', done => {
      wrapper.vm
        .$nextTick()
        .then(() => {
          const dashboardDropdown = wrapper.find('.js-dashboards-dropdown');

          expect(dashboardDropdown.exists()).toBe(true);
          done();
        })
        .catch(done.fail);
    });
  });

  describe('external dashboard link', () => {
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);

      createMountedWrapper(
        {
          hasMetrics: true,
          showPanels: false,
          showTimeWindowDropdown: false,
          externalDashboardUrl: '/mockUrl',
        },
        { attachToDocument: true, stubs: ['graph-group', 'panel-type'] },
      );
    });

    it('shows the link', done => {
      wrapper.vm
        .$nextTick()
        .then(() => {
          const externalDashboardButton = wrapper.find('.js-external-dashboard-link');

          expect(externalDashboardButton.exists()).toBe(true);
          expect(externalDashboardButton.is(GlButton)).toBe(true);
          expect(externalDashboardButton.text()).toContain('View full dashboard');
          done();
        })
        .catch(done.fail);
    });
  });

  // https://gitlab.com/gitlab-org/gitlab-ce/issues/66922
  // eslint-disable-next-line jest/no-disabled-tests
  describe.skip('link to chart', () => {
    const currentDashboard = 'TEST_DASHBOARD';
    localVue.use(GlToast);
    const link = () => wrapper.find('.js-chart-link');
    const clipboardText = () => link().element.dataset.clipboardText;

    beforeEach(done => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);

      createShallowWrapper({ hasMetrics: true, currentDashboard }, { attachToDocument: true });

      setTimeout(done);
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('adds a copy button to the dropdown', () => {
      expect(link().text()).toContain('Generate link to chart');
    });

    it('contains a link to the dashboard', () => {
      expect(clipboardText()).toContain(`dashboard=${currentDashboard}`);
      expect(clipboardText()).toContain(`group=`);
      expect(clipboardText()).toContain(`title=`);
      expect(clipboardText()).toContain(`y_label=`);
    });

    it('undefined parameter is stripped', done => {
      wrapper.setProps({ currentDashboard: undefined });

      wrapper.vm.$nextTick(() => {
        expect(clipboardText()).not.toContain(`dashboard=`);
        expect(clipboardText()).toContain(`y_label=`);
        done();
      });
    });

    it('null parameter is stripped', done => {
      wrapper.setProps({ currentDashboard: null });

      wrapper.vm.$nextTick(() => {
        expect(clipboardText()).not.toContain(`dashboard=`);
        expect(clipboardText()).toContain(`y_label=`);
        done();
      });
    });

    it('creates a toast when clicked', () => {
      jest.spyOn(wrapper.vm.$toast, 'show').and.stub();

      link().vm.$emit('click');

      expect(wrapper.vm.$toast.show).toHaveBeenCalled();
    });
  });
});

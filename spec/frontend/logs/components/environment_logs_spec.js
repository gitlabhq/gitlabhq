import Vue from 'vue';
import { GlDropdown, GlDropdownItem, GlSearchBoxByClick } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';
import EnvironmentLogs from '~/logs/components/environment_logs.vue';

import { createStore } from '~/logs/stores';
import { scrollDown } from '~/lib/utils/scroll_utils';
import {
  mockEnvName,
  mockEnvironments,
  mockPods,
  mockLogsResult,
  mockTrace,
  mockPodName,
  mockSearch,
  mockEnvironmentsEndpoint,
  mockDocumentationPath,
} from '../mock_data';

jest.mock('~/lib/utils/scroll_utils');

describe('EnvironmentLogs', () => {
  let EnvironmentLogsComponent;
  let store;
  let wrapper;
  let state;

  const propsData = {
    environmentName: mockEnvName,
    environmentsPath: mockEnvironmentsEndpoint,
    clusterApplicationsDocumentationPath: mockDocumentationPath,
  };

  const actionMocks = {
    setInitData: jest.fn(),
    setSearch: jest.fn(),
    showPodLogs: jest.fn(),
    showEnvironment: jest.fn(),
    fetchEnvironments: jest.fn(),
  };

  const updateControlBtnsMock = jest.fn();

  const findEnvironmentsDropdown = () => wrapper.find('.js-environments-dropdown');
  const findPodsDropdown = () => wrapper.find('.js-pods-dropdown');
  const findSearchBar = () => wrapper.find('.js-logs-search');
  const findTimeRangePicker = () => wrapper.find({ ref: 'dateTimePicker' });
  const findInfoAlert = () => wrapper.find('.js-elasticsearch-alert');

  const findLogControlButtons = () => wrapper.find({ name: 'log-control-buttons-stub' });
  const findLogTrace = () => wrapper.find('.js-log-trace');

  const mockSetInitData = () => {
    state.pods.options = mockPods;
    state.environments.current = mockEnvName;
    [state.pods.current] = state.pods.options;

    state.logs.isComplete = false;
    state.logs.lines = mockLogsResult;
  };

  const mockShowPodLogs = podName => {
    state.pods.options = mockPods;
    [state.pods.current] = podName;

    state.logs.isComplete = false;
    state.logs.lines = mockLogsResult;
  };

  const mockFetchEnvs = () => {
    state.environments.options = mockEnvironments;
  };

  const initWrapper = () => {
    wrapper = shallowMount(EnvironmentLogsComponent, {
      propsData,
      store,
      stubs: {
        LogControlButtons: {
          name: 'log-control-buttons-stub',
          template: '<div/>',
          methods: {
            update: updateControlBtnsMock,
          },
        },
      },
      methods: {
        ...actionMocks,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
    state = store.state.environmentLogs;
    EnvironmentLogsComponent = Vue.extend(EnvironmentLogs);
  });

  afterEach(() => {
    actionMocks.setInitData.mockReset();
    actionMocks.showPodLogs.mockReset();
    actionMocks.fetchEnvironments.mockReset();

    if (wrapper) {
      wrapper.destroy();
    }
  });

  it('displays UI elements', () => {
    initWrapper();

    expect(wrapper.isVueInstance()).toBe(true);
    expect(wrapper.isEmpty()).toBe(false);

    // top bar
    expect(findEnvironmentsDropdown().is(GlDropdown)).toBe(true);
    expect(findPodsDropdown().is(GlDropdown)).toBe(true);
    expect(findLogControlButtons().exists()).toBe(true);

    expect(findSearchBar().exists()).toBe(true);
    expect(findSearchBar().is(GlSearchBoxByClick)).toBe(true);
    expect(findTimeRangePicker().exists()).toBe(true);
    expect(findTimeRangePicker().is(DateTimePicker)).toBe(true);

    // log trace
    expect(findLogTrace().isEmpty()).toBe(false);
  });

  it('mounted inits data', () => {
    initWrapper();

    expect(actionMocks.setInitData).toHaveBeenCalledTimes(1);
    expect(actionMocks.setInitData).toHaveBeenLastCalledWith({
      timeRange: expect.objectContaining({
        default: true,
      }),
      environmentName: mockEnvName,
      podName: null,
    });

    expect(actionMocks.fetchEnvironments).toHaveBeenCalledTimes(1);
    expect(actionMocks.fetchEnvironments).toHaveBeenLastCalledWith(mockEnvironmentsEndpoint);
  });

  describe('loading state', () => {
    beforeEach(() => {
      state.pods.options = [];

      state.logs = {
        lines: [],
        isLoading: true,
      };

      state.environments = {
        options: [],
        isLoading: true,
      };

      initWrapper();
    });

    it('displays a disabled environments dropdown', () => {
      expect(findEnvironmentsDropdown().attributes('disabled')).toBe('true');
      expect(findEnvironmentsDropdown().findAll(GlDropdownItem).length).toBe(0);
    });

    it('displays a disabled pods dropdown', () => {
      expect(findPodsDropdown().attributes('disabled')).toBe('true');
      expect(findPodsDropdown().findAll(GlDropdownItem).length).toBe(0);
    });

    it('displays a disabled search bar', () => {
      expect(findSearchBar().exists()).toBe(true);
      expect(findSearchBar().attributes('disabled')).toBe('true');
    });

    it('displays a disabled time window dropdown', () => {
      expect(findTimeRangePicker().attributes('disabled')).toBe('true');
    });

    it('does not update buttons state', () => {
      expect(updateControlBtnsMock).not.toHaveBeenCalled();
    });

    it('shows a logs trace', () => {
      expect(findLogTrace().text()).toBe('');
      expect(
        findLogTrace()
          .find('.js-build-loader-animation')
          .isVisible(),
      ).toBe(true);
    });
  });

  describe('legacy environment', () => {
    beforeEach(() => {
      state.pods.options = [];

      state.logs = {
        lines: [],
        isLoading: false,
      };

      state.environments = {
        options: mockEnvironments,
        current: 'staging',
        isLoading: false,
      };

      initWrapper();
    });

    it('displays a disabled time window dropdown', () => {
      expect(findTimeRangePicker().attributes('disabled')).toBe('true');
    });

    it('displays a disabled search bar', () => {
      expect(findSearchBar().attributes('disabled')).toBe('true');
    });

    it('displays an alert to upgrade to ES', () => {
      expect(findInfoAlert().exists()).toBe(true);
    });
  });

  describe('state with data', () => {
    beforeEach(() => {
      actionMocks.setInitData.mockImplementation(mockSetInitData);
      actionMocks.showPodLogs.mockImplementation(mockShowPodLogs);
      actionMocks.fetchEnvironments.mockImplementation(mockFetchEnvs);

      initWrapper();
    });

    afterEach(() => {
      scrollDown.mockReset();
      updateControlBtnsMock.mockReset();

      actionMocks.setInitData.mockReset();
      actionMocks.showPodLogs.mockReset();
      actionMocks.fetchEnvironments.mockReset();
    });

    it('displays an enabled search bar', () => {
      expect(findSearchBar().attributes('disabled')).toBeFalsy();

      // input a query and click `search`
      findSearchBar().vm.$emit('input', mockSearch);
      findSearchBar().vm.$emit('submit');

      expect(actionMocks.setSearch).toHaveBeenCalledTimes(1);
      expect(actionMocks.setSearch).toHaveBeenCalledWith(mockSearch);
    });

    it('displays an enabled time window dropdown', () => {
      expect(findTimeRangePicker().attributes('disabled')).toBeFalsy();
    });

    it('does not display an alert to upgrade to ES', () => {
      expect(findInfoAlert().exists()).toBe(false);
    });

    it('populates environments dropdown', () => {
      const items = findEnvironmentsDropdown().findAll(GlDropdownItem);
      expect(findEnvironmentsDropdown().props('text')).toBe(mockEnvName);
      expect(items.length).toBe(mockEnvironments.length);
      mockEnvironments.forEach((env, i) => {
        const item = items.at(i);
        expect(item.text()).toBe(env.name);
      });
    });

    it('populates pods dropdown', () => {
      const items = findPodsDropdown().findAll(GlDropdownItem);

      expect(findPodsDropdown().props('text')).toBe(mockPodName);
      expect(items.length).toBe(mockPods.length);
      mockPods.forEach((pod, i) => {
        const item = items.at(i);
        expect(item.text()).toBe(pod);
      });
    });

    it('populates logs trace', () => {
      const trace = findLogTrace();
      expect(trace.text().split('\n').length).toBe(mockTrace.length);
      expect(trace.text().split('\n')).toEqual(mockTrace);
    });

    it('update control buttons state', () => {
      expect(updateControlBtnsMock).toHaveBeenCalledTimes(1);
    });

    it('scrolls to bottom when loaded', () => {
      expect(scrollDown).toHaveBeenCalledTimes(1);
    });

    describe('when user clicks', () => {
      it('environment name, trace is refreshed', () => {
        const items = findEnvironmentsDropdown().findAll(GlDropdownItem);
        const index = 1; // any env

        expect(actionMocks.showEnvironment).toHaveBeenCalledTimes(0);

        items.at(index).vm.$emit('click');

        expect(actionMocks.showEnvironment).toHaveBeenCalledTimes(1);
        expect(actionMocks.showEnvironment).toHaveBeenLastCalledWith(mockEnvironments[index].name);
      });

      it('pod name, trace is refreshed', () => {
        const items = findPodsDropdown().findAll(GlDropdownItem);
        const index = 2; // any pod

        expect(actionMocks.showPodLogs).toHaveBeenCalledTimes(0);

        items.at(index).vm.$emit('click');

        expect(actionMocks.showPodLogs).toHaveBeenCalledTimes(1);
        expect(actionMocks.showPodLogs).toHaveBeenLastCalledWith(mockPods[index]);
      });

      it('refresh button, trace is refreshed', () => {
        expect(actionMocks.showPodLogs).toHaveBeenCalledTimes(0);

        findLogControlButtons().vm.$emit('refresh');

        expect(actionMocks.showPodLogs).toHaveBeenCalledTimes(1);
        expect(actionMocks.showPodLogs).toHaveBeenLastCalledWith(mockPodName);
      });
    });
  });
});

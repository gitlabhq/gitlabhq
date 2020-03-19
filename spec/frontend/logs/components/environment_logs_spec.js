import Vue from 'vue';
import { GlSprintf, GlDropdown, GlDropdownItem, GlSearchBoxByClick } from '@gitlab/ui';
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

const module = 'environmentLogs';

jest.mock('lodash/throttle', () =>
  jest.fn(func => {
    return func;
  }),
);

describe('EnvironmentLogs', () => {
  let EnvironmentLogsComponent;
  let store;
  let dispatch;
  let wrapper;
  let state;

  const propsData = {
    environmentName: mockEnvName,
    environmentsPath: mockEnvironmentsEndpoint,
    clusterApplicationsDocumentationPath: mockDocumentationPath,
  };

  const updateControlBtnsMock = jest.fn();

  const findEnvironmentsDropdown = () => wrapper.find('.js-environments-dropdown');
  const findPodsDropdown = () => wrapper.find('.js-pods-dropdown');
  const findSearchBar = () => wrapper.find('.js-logs-search');
  const findTimeRangePicker = () => wrapper.find({ ref: 'dateTimePicker' });
  const findInfoAlert = () => wrapper.find('.js-elasticsearch-alert');
  const findLogControlButtons = () => wrapper.find({ name: 'log-control-buttons-stub' });

  const findInfiniteScroll = () => wrapper.find({ ref: 'infiniteScroll' });
  const findLogTrace = () => wrapper.find('.js-log-trace');
  const findLogFooter = () => wrapper.find({ ref: 'logFooter' });
  const getInfiniteScrollAttr = attr => parseInt(findInfiniteScroll().attributes(attr), 10);

  const mockSetInitData = () => {
    state.pods.options = mockPods;
    state.environments.current = mockEnvName;
    [state.pods.current] = state.pods.options;

    state.logs.lines = [];
  };

  const mockShowPodLogs = () => {
    state.pods.options = mockPods;
    [state.pods.current] = mockPods;

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
          props: {
            scrollDownButtonDisabled: false,
          },
        },
        GlInfiniteScroll: {
          name: 'gl-infinite-scroll',
          template: `
          <div>
            <slot name="header"></slot>
            <slot name="items"></slot>
            <slot></slot>
          </div>
          `,
        },
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
    state = store.state.environmentLogs;
    EnvironmentLogsComponent = Vue.extend(EnvironmentLogs);

    jest.spyOn(store, 'dispatch').mockResolvedValue();

    dispatch = store.dispatch;
  });

  afterEach(() => {
    store.dispatch.mockReset();

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
    expect(findInfiniteScroll().exists()).toBe(true);
    expect(findLogTrace().exists()).toBe(true);
  });

  it('mounted inits data', () => {
    initWrapper();

    expect(dispatch).toHaveBeenCalledWith(`${module}/setInitData`, {
      timeRange: expect.objectContaining({
        default: true,
      }),
      environmentName: mockEnvName,
      podName: null,
    });

    expect(dispatch).toHaveBeenCalledWith(`${module}/fetchEnvironments`, mockEnvironmentsEndpoint);
  });

  describe('loading state', () => {
    beforeEach(() => {
      state.pods.options = [];

      state.logs.lines = [];
      state.logs.isLoading = true;

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

    it('shows an infinite scroll with height and no content', () => {
      expect(getInfiniteScrollAttr('max-list-height')).toBeGreaterThan(0);
      expect(getInfiniteScrollAttr('fetched-items')).toBe(0);
    });

    it('shows an infinite scroll container with equal height and max-height ', () => {
      const height = getInfiniteScrollAttr('max-list-height');

      expect(height).toEqual(expect.any(Number));
      expect(findInfiniteScroll().attributes('style')).toMatch(`height: ${height}px;`);
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

  describe('k8s environment', () => {
    beforeEach(() => {
      state.pods.options = [];

      state.logs.lines = [];
      state.logs.isLoading = false;

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
      dispatch.mockImplementation(actionName => {
        if (actionName === `${module}/setInitData`) {
          mockSetInitData();
        } else if (actionName === `${module}/showPodLogs`) {
          mockShowPodLogs();
        } else if (actionName === `${module}/fetchEnvironments`) {
          mockFetchEnvs();
          mockShowPodLogs();
        }
      });

      initWrapper();
    });

    afterEach(() => {
      scrollDown.mockReset();
      updateControlBtnsMock.mockReset();
    });

    it('displays an enabled search bar', () => {
      expect(findSearchBar().attributes('disabled')).toBeFalsy();

      // input a query and click `search`
      findSearchBar().vm.$emit('input', mockSearch);
      findSearchBar().vm.$emit('submit');

      expect(dispatch).toHaveBeenCalledWith(`${module}/setInitData`, expect.any(Object));
      expect(dispatch).toHaveBeenCalledWith(`${module}/setSearch`, mockSearch);
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

    it('shows infinite scroll with height and no content', () => {
      expect(getInfiniteScrollAttr('max-list-height')).toBeGreaterThan(0);
      expect(getInfiniteScrollAttr('fetched-items')).toBe(mockTrace.length);
    });

    it('populates logs trace', () => {
      const trace = findLogTrace();
      expect(trace.text().split('\n').length).toBe(mockTrace.length);
      expect(trace.text().split('\n')).toEqual(mockTrace);
    });

    it('populates footer', () => {
      const footer = findLogFooter().text();

      expect(footer).toContain(`${mockLogsResult.length} results`);
    });

    describe('when user clicks', () => {
      it('environment name, trace is refreshed', () => {
        const items = findEnvironmentsDropdown().findAll(GlDropdownItem);
        const index = 1; // any env

        expect(dispatch).not.toHaveBeenCalledWith(`${module}/showEnvironment`, expect.anything());

        items.at(index).vm.$emit('click');

        expect(dispatch).toHaveBeenCalledWith(
          `${module}/showEnvironment`,
          mockEnvironments[index].name,
        );
      });

      it('pod name, trace is refreshed', () => {
        const items = findPodsDropdown().findAll(GlDropdownItem);
        const index = 2; // any pod

        expect(dispatch).not.toHaveBeenCalledWith(`${module}/showPodLogs`, expect.anything());

        items.at(index).vm.$emit('click');

        expect(dispatch).toHaveBeenCalledWith(`${module}/showPodLogs`, mockPods[index]);
      });

      it('refresh button, trace is refreshed', () => {
        expect(dispatch).not.toHaveBeenCalledWith(`${module}/showPodLogs`, expect.anything());

        findLogControlButtons().vm.$emit('refresh');

        expect(dispatch).toHaveBeenCalledWith(`${module}/showPodLogs`, mockPodName);
      });
    });
  });

  describe('listeners', () => {
    beforeEach(() => {
      initWrapper();
    });

    it('attaches listeners in components', () => {
      expect(findInfiniteScroll().vm.$listeners).toEqual({
        topReached: expect.any(Function),
        scroll: expect.any(Function),
      });
    });

    it('`topReached` when not loading', () => {
      expect(store.dispatch).not.toHaveBeenCalledWith(`${module}/fetchMoreLogsPrepend`, undefined);

      findInfiniteScroll().vm.$emit('topReached');

      expect(store.dispatch).toHaveBeenCalledWith(`${module}/fetchMoreLogsPrepend`, undefined);
    });

    it('`topReached` does not fetches more logs when already loading', () => {
      state.logs.isLoading = true;
      findInfiniteScroll().vm.$emit('topReached');

      expect(store.dispatch).not.toHaveBeenCalledWith(`${module}/fetchMoreLogsPrepend`, undefined);
    });

    it('`topReached` fetches more logs', () => {
      state.logs.isLoading = true;
      findInfiniteScroll().vm.$emit('topReached');

      expect(store.dispatch).not.toHaveBeenCalledWith(`${module}/fetchMoreLogsPrepend`, undefined);
    });

    it('`scroll` on a scrollable target results in enabled scroll buttons', () => {
      const target = { scrollTop: 10, clientHeight: 10, scrollHeight: 21 };

      state.logs.isLoading = true;
      findInfiniteScroll().vm.$emit('scroll', { target });

      return wrapper.vm.$nextTick(() => {
        expect(findLogControlButtons().props('scrollDownButtonDisabled')).toEqual(false);
      });
    });

    it('`scroll` on a non-scrollable target in disabled scroll buttons', () => {
      const target = { scrollTop: 10, clientHeight: 10, scrollHeight: 20 };

      state.logs.isLoading = true;
      findInfiniteScroll().vm.$emit('scroll', { target });

      return wrapper.vm.$nextTick(() => {
        expect(findLogControlButtons().props('scrollDownButtonDisabled')).toEqual(true);
      });
    });

    it('`scroll` on no target results in disabled scroll buttons', () => {
      state.logs.isLoading = true;
      findInfiniteScroll().vm.$emit('scroll', { target: undefined });

      return wrapper.vm.$nextTick(() => {
        expect(findLogControlButtons().props('scrollDownButtonDisabled')).toEqual(true);
      });
    });
  });
});

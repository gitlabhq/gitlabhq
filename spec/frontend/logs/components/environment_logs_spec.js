import { GlSprintf, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { scrollDown } from '~/lib/utils/scroll_utils';
import EnvironmentLogs from '~/logs/components/environment_logs.vue';

import { createStore } from '~/logs/stores';
import {
  mockEnvName,
  mockEnvironments,
  mockPods,
  mockLogsResult,
  mockTrace,
  mockEnvironmentsEndpoint,
  mockDocumentationPath,
} from '../mock_data';

jest.mock('~/lib/utils/scroll_utils');

const module = 'environmentLogs';

jest.mock('lodash/throttle', () =>
  jest.fn((func) => {
    return func;
  }),
);

describe('EnvironmentLogs', () => {
  let store;
  let dispatch;
  let wrapper;
  let state;

  const propsData = {
    environmentName: mockEnvName,
    environmentsPath: mockEnvironmentsEndpoint,
    clusterApplicationsDocumentationPath: mockDocumentationPath,
    clustersPath: '/gitlab-org',
  };

  const updateControlBtnsMock = jest.fn();
  const LogControlButtonsStub = {
    template: '<div/>',
    methods: {
      update: updateControlBtnsMock,
    },
    props: {
      scrollDownButtonDisabled: false,
    },
  };

  const findEnvironmentsDropdown = () => wrapper.find('.js-environments-dropdown');

  const findSimpleFilters = () => wrapper.find({ ref: 'log-simple-filters' });
  const findAdvancedFilters = () => wrapper.find({ ref: 'log-advanced-filters' });
  const findElasticsearchNotice = () => wrapper.find({ ref: 'elasticsearchNotice' });
  const findLogControlButtons = () => wrapper.find(LogControlButtonsStub);

  const findInfiniteScroll = () => wrapper.find({ ref: 'infiniteScroll' });
  const findLogTrace = () => wrapper.find({ ref: 'logTrace' });
  const findLogFooter = () => wrapper.find({ ref: 'logFooter' });
  const getInfiniteScrollAttr = (attr) => parseInt(findInfiniteScroll().attributes(attr), 10);

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
    wrapper = shallowMount(EnvironmentLogs, {
      propsData,
      store,
      stubs: {
        LogControlButtons: LogControlButtonsStub,
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

    expect(findEnvironmentsDropdown().is(GlDropdown)).toBe(true);
    expect(findSimpleFilters().exists()).toBe(true);
    expect(findLogControlButtons().exists()).toBe(true);

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

    it('does not display an alert to upgrade to ES', () => {
      expect(findElasticsearchNotice().exists()).toBe(false);
    });

    it('displays a disabled environments dropdown', () => {
      expect(findEnvironmentsDropdown().attributes('disabled')).toBe('true');
      expect(findEnvironmentsDropdown().findAll(GlDropdownItem).length).toBe(0);
    });

    it('does not update buttons state', () => {
      expect(updateControlBtnsMock).not.toHaveBeenCalled();
    });

    it('shows an infinite scroll with no content', () => {
      expect(getInfiniteScrollAttr('fetched-items')).toBe(0);
    });

    it('shows an infinite scroll container with no set max-height ', () => {
      expect(findInfiniteScroll().attributes('max-list-height')).toBeUndefined();
    });

    it('shows a logs trace', () => {
      expect(findLogTrace().text()).toBe('');
      expect(findLogTrace().find('.js-build-loader-animation').isVisible()).toBe(true);
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

    it('displays an alert to upgrade to ES', () => {
      expect(findElasticsearchNotice().exists()).toBe(true);
    });

    it('displays simple filters for kubernetes logs API', () => {
      expect(findSimpleFilters().exists()).toBe(true);
      expect(findAdvancedFilters().exists()).toBe(false);
    });
  });

  describe('state with data', () => {
    beforeEach(() => {
      dispatch.mockImplementation((actionName) => {
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

    it('does not display an alert to upgrade to ES', () => {
      expect(findElasticsearchNotice().exists()).toBe(false);
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

    it('dropdown has one environment selected', () => {
      const items = findEnvironmentsDropdown().findAll(GlDropdownItem);
      mockEnvironments.forEach((env, i) => {
        const item = items.at(i);

        if (item.text() !== mockEnvName) {
          expect(item.find(GlDropdownItem).attributes('ischecked')).toBeFalsy();
        } else {
          expect(item.find(GlDropdownItem).attributes('ischecked')).toBeTruthy();
        }
      });
    });

    it('displays advanced filters for elasticsearch logs API', () => {
      expect(findSimpleFilters().exists()).toBe(false);
      expect(findAdvancedFilters().exists()).toBe(true);
    });

    it('shows infinite scroll with content', () => {
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

      it('refresh button, trace is refreshed', () => {
        expect(dispatch).not.toHaveBeenCalledWith(`${module}/refreshPodLogs`, undefined);

        findLogControlButtons().vm.$emit('refresh');

        expect(dispatch).toHaveBeenCalledWith(`${module}/refreshPodLogs`, undefined);
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

import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import Log from '~/jobs/components/log/log.vue';
import LogLineHeader from '~/jobs/components/log/line_header.vue';
import { logLinesParser } from '~/jobs/store/utils';
import { jobLog } from './mock_data';

describe('Job Log', () => {
  let wrapper;
  let actions;
  let state;
  let store;
  let toggleCollapsibleLineMock;

  Vue.use(Vuex);

  const createComponent = () => {
    wrapper = mount(Log, {
      store,
    });
  };

  beforeEach(() => {
    toggleCollapsibleLineMock = jest.fn();
    actions = {
      toggleCollapsibleLine: toggleCollapsibleLineMock,
    };

    state = {
      jobLog: logLinesParser(jobLog),
      jobLogEndpoint: 'jobs/id',
    };

    store = new Vuex.Store({
      actions,
      state,
    });

    createComponent();
  });

  const findCollapsibleLine = () => wrapper.findComponent(LogLineHeader);

  describe('line numbers', () => {
    it('renders a line number for each open line', () => {
      expect(wrapper.find('#L1').text()).toBe('1');
      expect(wrapper.find('#L2').text()).toBe('2');
      expect(wrapper.find('#L3').text()).toBe('3');
    });

    it('links to the provided path and correct line number', () => {
      expect(wrapper.find('#L1').attributes('href')).toBe(`${state.jobLogEndpoint}#L1`);
    });
  });

  describe('collapsible sections', () => {
    it('renders a clickable header section', () => {
      expect(findCollapsibleLine().attributes('role')).toBe('button');
    });

    it('renders an icon with the open state', () => {
      expect(findCollapsibleLine().find('[data-testid="chevron-lg-down-icon"]').exists()).toBe(
        true,
      );
    });

    describe('on click header section', () => {
      it('calls toggleCollapsibleLine', () => {
        findCollapsibleLine().trigger('click');

        expect(toggleCollapsibleLineMock).toHaveBeenCalled();
      });
    });
  });
});

import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { logLinesParser } from '~/jobs/store/utils';
import Log from '~/jobs/components/log/log.vue';
import { jobLog } from './mock_data';

describe('Job Log', () => {
  let wrapper;
  let actions;
  let state;
  let store;

  const localVue = createLocalVue();
  localVue.use(Vuex);

  const createComponent = () => {
    wrapper = mount(Log, {
      localVue,
      store,
    });
  };

  beforeEach(() => {
    actions = {
      toggleCollapsibleLine: () => {},
    };

    state = {
      trace: logLinesParser(jobLog),
      traceEndpoint: 'jobs/id',
    };

    store = new Vuex.Store({
      actions,
      state,
    });

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('line numbers', () => {
    it('renders a line number for each open line', () => {
      expect(wrapper.find('#L1').text()).toBe('1');
      expect(wrapper.find('#L2').text()).toBe('2');
      expect(wrapper.find('#L3').text()).toBe('3');
    });

    it('links to the provided path and correct line number', () => {
      expect(wrapper.find('#L1').attributes('href')).toBe(`${state.traceEndpoint}#L1`);
    });
  });

  describe('collapsible sections', () => {
    it('renders a clickable header section', () => {
      expect(wrapper.find('.collapsible-line').attributes('role')).toBe('button');
    });

    it('renders an icon with the open state', () => {
      expect(wrapper.find('.collapsible-line svg').classes()).toContain('ic-angle-down');
    });

    describe('on click header section', () => {
      it('calls toggleCollapsibleLine', () => {
        jest.spyOn(wrapper.vm, 'toggleCollapsibleLine');

        wrapper.find('.collapsible-line').trigger('click');

        expect(wrapper.vm.toggleCollapsibleLine).toHaveBeenCalled();
      });
    });
  });
});

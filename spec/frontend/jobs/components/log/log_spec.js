import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import Log from '~/jobs/components/log/log.vue';
import { logLinesParserLegacy, logLinesParser } from '~/jobs/store/utils';
import { jobLog } from './mock_data';

describe('Job Log', () => {
  let wrapper;
  let actions;
  let state;
  let store;
  let origGon;

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

    origGon = window.gon;

    window.gon = { features: { infinitelyCollapsibleSections: false } };

    state = {
      trace: logLinesParserLegacy(jobLog),
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

    window.gon = origGon;
  });

  const findCollapsibleLine = () => wrapper.find('.collapsible-line');

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
      expect(findCollapsibleLine().attributes('role')).toBe('button');
    });

    it('renders an icon with the open state', () => {
      expect(findCollapsibleLine().find('[data-testid="angle-down-icon"]').exists()).toBe(true);
    });

    describe('on click header section', () => {
      it('calls toggleCollapsibleLine', () => {
        jest.spyOn(wrapper.vm, 'toggleCollapsibleLine');

        findCollapsibleLine().trigger('click');

        expect(wrapper.vm.toggleCollapsibleLine).toHaveBeenCalled();
      });
    });
  });
});

describe('Job Log, infinitelyCollapsibleSections feature flag enabled', () => {
  let wrapper;
  let actions;
  let state;
  let store;
  let origGon;

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

    origGon = window.gon;

    window.gon = { features: { infinitelyCollapsibleSections: true } };

    state = {
      trace: logLinesParser(jobLog).parsedLines,
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

    window.gon = origGon;
  });

  const findCollapsibleLine = () => wrapper.find('.collapsible-line');

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
      expect(findCollapsibleLine().attributes('role')).toBe('button');
    });

    it('renders an icon with the open state', () => {
      expect(findCollapsibleLine().find('[data-testid="angle-down-icon"]').exists()).toBe(true);
    });

    describe('on click header section', () => {
      it('calls toggleCollapsibleLine', () => {
        jest.spyOn(wrapper.vm, 'toggleCollapsibleLine');

        findCollapsibleLine().trigger('click');

        expect(wrapper.vm.toggleCollapsibleLine).toHaveBeenCalled();
      });
    });
  });
});

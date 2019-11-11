import { shallowMount } from '@vue/test-utils';
import Stacktrace from '~/error_tracking/components/stacktrace.vue';
import StackTraceEntry from '~/error_tracking/components/stacktrace_entry.vue';

describe('ErrorDetails', () => {
  let wrapper;

  const stackTraceEntry = {
    filename: 'sidekiq/util.rb',
    context: [
      [22, '    def safe_thread(name, \u0026block)\n'],
      [23, '      Thread.new do\n'],
      [24, "        Thread.current['sidekiq_label'] = name\n"],
      [25, '        watchdog(name, \u0026block)\n'],
    ],
    lineNo: 24,
  };

  function mountComponent(entries) {
    wrapper = shallowMount(Stacktrace, {
      propsData: {
        entries,
      },
    });
  }

  describe('Stacktrace', () => {
    afterEach(() => {
      if (wrapper) {
        wrapper.destroy();
      }
    });

    it('should render single Stacktrace entry', () => {
      mountComponent([stackTraceEntry]);
      expect(wrapper.findAll(StackTraceEntry).length).toBe(1);
    });

    it('should render multiple Stacktrace entry', () => {
      const entriesNum = 3;
      mountComponent(new Array(entriesNum).fill(stackTraceEntry));
      expect(wrapper.findAll(StackTraceEntry).length).toBe(entriesNum);
    });
  });
});

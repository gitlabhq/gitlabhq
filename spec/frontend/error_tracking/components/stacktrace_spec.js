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
    function: 'fn',
    colNo: 1,
  };

  function mountComponent(entries) {
    wrapper = shallowMount(Stacktrace, {
      propsData: {
        entries,
      },
    });
  }

  describe('Stacktrace', () => {
    it('should render single Stacktrace entry', () => {
      mountComponent([stackTraceEntry]);
      const allEntries = wrapper.findAllComponents(StackTraceEntry);
      expect(allEntries.length).toBe(1);
      const entry = allEntries.at(0);
      expect(entry.props()).toEqual({
        lines: stackTraceEntry.context,
        filePath: stackTraceEntry.filename,
        errorLine: stackTraceEntry.lineNo,
        errorFn: stackTraceEntry.function,
        errorColumn: stackTraceEntry.colNo,
        expanded: true,
      });
    });

    it('should render multiple Stacktrace entry', () => {
      const entriesNum = 3;
      mountComponent(new Array(entriesNum).fill(stackTraceEntry));
      const entries = wrapper.findAllComponents(StackTraceEntry);
      expect(entries.length).toBe(entriesNum);
      expect(entries.at(0).props('expanded')).toBe(true);
      expect(entries.at(1).props('expanded')).toBe(false);
      expect(entries.at(2).props('expanded')).toBe(false);
    });

    it('should use the entry abs_path if filename is missing', () => {
      mountComponent([{ ...stackTraceEntry, filename: undefined, abs_path: 'abs_path' }]);

      expect(wrapper.findComponent(StackTraceEntry).props('filePath')).toBe('abs_path');
    });
  });
});

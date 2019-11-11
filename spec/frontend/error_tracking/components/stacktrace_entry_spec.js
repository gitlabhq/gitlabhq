import { shallowMount } from '@vue/test-utils';
import StackTraceEntry from '~/error_tracking/components/stacktrace_entry.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import Icon from '~/vue_shared/components/icon.vue';

describe('Stacktrace Entry', () => {
  let wrapper;

  function mountComponent(props) {
    wrapper = shallowMount(StackTraceEntry, {
      propsData: {
        filePath: 'sidekiq/util.rb',
        lines: [
          [22, '    def safe_thread(name, \u0026block)\n'],
          [23, '      Thread.new do\n'],
          [24, "        Thread.current['sidekiq_label'] = name\n"],
          [25, '        watchdog(name, \u0026block)\n'],
        ],
        errorLine: 24,
        ...props,
      },
    });
  }

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  it('should render stacktrace entry collapsed', () => {
    expect(wrapper.find(StackTraceEntry).exists()).toBe(true);
    expect(wrapper.find(ClipboardButton).exists()).toBe(true);
    expect(wrapper.find(Icon).exists()).toBe(true);
    expect(wrapper.find(FileIcon).exists()).toBe(true);
    expect(wrapper.element.querySelectorAll('table').length).toBe(0);
  });

  it('should render stacktrace entry table expanded', () => {
    mountComponent({ expanded: true });
    expect(wrapper.element.querySelectorAll('tr.line_holder').length).toBe(4);
    expect(wrapper.element.querySelectorAll('.line_content.old').length).toBe(1);
  });
});

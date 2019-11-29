import { shallowMount } from '@vue/test-utils';
import StackTraceEntry from '~/error_tracking/components/stacktrace_entry.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import Icon from '~/vue_shared/components/icon.vue';

describe('Stacktrace Entry', () => {
  let wrapper;

  const lines = [
    [22, '    def safe_thread(name, \u0026block)\n'],
    [23, '      Thread.new do\n'],
    [24, "        Thread.current['sidekiq_label'] = name\n"],
    [25, '        watchdog(name, \u0026block)\n'],
  ];

  function mountComponent(props) {
    wrapper = shallowMount(StackTraceEntry, {
      propsData: {
        filePath: 'sidekiq/util.rb',
        errorLine: 24,
        ...props,
      },
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  it('should render stacktrace entry collapsed', () => {
    mountComponent({ lines });
    expect(wrapper.find(StackTraceEntry).exists()).toBe(true);
    expect(wrapper.find(ClipboardButton).exists()).toBe(true);
    expect(wrapper.find(Icon).exists()).toBe(true);
    expect(wrapper.find(FileIcon).exists()).toBe(true);
    expect(wrapper.find('table').exists()).toBe(false);
  });

  it('should render stacktrace entry table expanded', () => {
    mountComponent({ expanded: true, lines });
    expect(wrapper.find('table').exists()).toBe(true);
    expect(wrapper.findAll('tr.line_holder').length).toBe(4);
    expect(wrapper.findAll('.line_content.old').length).toBe(1);
  });

  describe('no code block', () => {
    const findFileHeaderContent = () => wrapper.find('.file-header-content').html();

    it('should hide collapse icon and render error fn name and error line when there is no code block', () => {
      const extraInfo = { errorLine: 34, errorFn: 'errorFn', errorColumn: 77 };
      mountComponent({ expanded: false, lines: [], ...extraInfo });
      expect(wrapper.find(Icon).exists()).toBe(false);
      expect(findFileHeaderContent()).toContain(
        `in ${extraInfo.errorFn} at line ${extraInfo.errorLine}:${extraInfo.errorColumn}`,
      );
    });

    it('should render only lineNo:columnNO when there is no errorFn ', () => {
      const extraInfo = { errorLine: 34, errorFn: null, errorColumn: 77 };
      mountComponent({ expanded: false, lines: [], ...extraInfo });
      expect(findFileHeaderContent()).not.toContain(`in ${extraInfo.errorFn}`);
      expect(findFileHeaderContent()).toContain(`${extraInfo.errorLine}:${extraInfo.errorColumn}`);
    });

    it('should render only lineNo when there is no errorColumn ', () => {
      const extraInfo = { errorLine: 34, errorFn: 'errorFn', errorColumn: null };
      mountComponent({ expanded: false, lines: [], ...extraInfo });
      expect(findFileHeaderContent()).toContain(
        `in ${extraInfo.errorFn} at line ${extraInfo.errorLine}`,
      );
      expect(findFileHeaderContent()).not.toContain(`:${extraInfo.errorColumn}`);
    });
  });
});

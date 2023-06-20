import { GlSprintf, GlIcon, GlTruncate } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import StackTraceEntry from '~/error_tracking/components/stacktrace_entry.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';

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
      stubs: {
        GlSprintf,
      },
    });
  }

  it('should render stacktrace entry collapsed', () => {
    mountComponent({ lines });
    expect(wrapper.findComponent(StackTraceEntry).exists()).toBe(true);
    expect(wrapper.findComponent(ClipboardButton).exists()).toBe(true);
    expect(wrapper.findComponent(GlIcon).exists()).toBe(true);
    expect(wrapper.findComponent(FileIcon).exists()).toBe(true);
    expect(wrapper.find('table').exists()).toBe(false);
  });

  it('should render stacktrace entry table expanded', () => {
    mountComponent({ expanded: true, lines });
    expect(wrapper.find('table').exists()).toBe(true);
    expect(wrapper.findAll('tr.line_holder').length).toBe(4);
    expect(wrapper.findAll('.line_content.old').length).toBe(1);
  });

  it('should render file information if filePath exists', () => {
    mountComponent({ lines });
    expect(wrapper.findComponent(FileIcon).exists()).toBe(true);
    expect(wrapper.findComponent(ClipboardButton).exists()).toBe(true);
    expect(wrapper.findComponent(GlTruncate).exists()).toBe(true);
    expect(wrapper.findComponent(GlTruncate).props('text')).toBe('sidekiq/util.rb');
  });

  it('should not render file information if filePath does not exists', () => {
    mountComponent({ lines, filePath: undefined });
    expect(wrapper.findComponent(FileIcon).exists()).toBe(false);
    expect(wrapper.findComponent(ClipboardButton).exists()).toBe(false);
    expect(wrapper.findComponent(GlTruncate).exists()).toBe(false);
  });

  describe('entry caption', () => {
    const findFileHeaderContent = () => wrapper.find('.file-header-content').text();

    it('should hide collapse icon and render error fn name and error line when there is no code block', () => {
      const extraInfo = { errorLine: 34, errorFn: 'errorFn', errorColumn: 77 };
      mountComponent({ expanded: false, lines: [], ...extraInfo });
      expect(wrapper.findComponent(GlIcon).exists()).toBe(false);
      expect(trimText(findFileHeaderContent())).toContain(
        `in ${extraInfo.errorFn} at line ${extraInfo.errorLine}:${extraInfo.errorColumn}`,
      );
    });

    it('should render only lineNo:columnNO when there is no errorFn', () => {
      const extraInfo = { errorLine: 34, errorFn: null, errorColumn: 77 };
      mountComponent({ expanded: false, lines: [], ...extraInfo });
      const fileHeaderContent = trimText(findFileHeaderContent());
      expect(fileHeaderContent).not.toContain(`in ${extraInfo.errorFn}`);
      expect(fileHeaderContent).toContain(`${extraInfo.errorLine}:${extraInfo.errorColumn}`);
    });

    it('should render only lineNo when there is no errorColumn', () => {
      const extraInfo = { errorLine: 34, errorFn: 'errorFn', errorColumn: null };
      mountComponent({ expanded: false, lines: [], ...extraInfo });
      const fileHeaderContent = trimText(findFileHeaderContent());
      expect(fileHeaderContent).toContain(`in ${extraInfo.errorFn} at line ${extraInfo.errorLine}`);
      expect(fileHeaderContent).not.toContain(`:${extraInfo.errorColumn}`);
    });
  });
});

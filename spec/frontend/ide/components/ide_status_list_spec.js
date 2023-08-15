import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import IdeStatusList from '~/ide/components/ide_status_list.vue';
import TerminalSyncStatusSafe from '~/ide/components/terminal_sync/terminal_sync_status_safe.vue';

const TEST_FILE = {
  name: 'lorem.md',
  content: 'abc\nndef',
  permalink: '/lorem.md',
};
const TEST_FILE_EDITOR = {
  fileLanguage: 'markdown',
  editorRow: 3,
  editorColumn: 23,
};
const TEST_EDITOR_POSITION = `${TEST_FILE_EDITOR.editorRow}:${TEST_FILE_EDITOR.editorColumn}`;

Vue.use(Vuex);

describe('ide/components/ide_status_list', () => {
  let activeFileEditor;
  let activeFile;
  let store;
  let wrapper;

  const findLink = () => wrapper.findComponent(GlLink);
  const createComponent = (options = {}) => {
    store = new Vuex.Store({
      getters: {
        activeFile: () => activeFile,
      },
      modules: {
        editor: {
          namespaced: true,
          getters: {
            activeFileEditor: () => activeFileEditor,
          },
        },
      },
    });

    wrapper = shallowMount(IdeStatusList, {
      store,
      ...options,
    });
  };

  beforeEach(() => {
    activeFile = TEST_FILE;
    activeFileEditor = TEST_FILE_EDITOR;
  });

  afterEach(() => {
    store = null;
  });

  describe('with regular file', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a link to the file that contains the file name', () => {
      expect(findLink().attributes('href')).toBe(TEST_FILE.permalink);
      expect(findLink().text()).toBe(TEST_FILE.name);
    });

    it('shows file eol', () => {
      expect(wrapper.text()).not.toContain('CRLF');
      expect(wrapper.text()).toContain('LF');
    });

    it('shows file editor position', () => {
      expect(wrapper.text()).toContain(TEST_EDITOR_POSITION);
    });

    it('shows file language', () => {
      expect(wrapper.text()).toContain(TEST_FILE_EDITOR.fileLanguage);
    });
  });

  describe('with binary file', () => {
    beforeEach(() => {
      activeFile.name = 'abc.dat';
      activeFile.content = '🐱'; // non-ascii binary content
      createComponent();
    });

    it('does not show file editor position', () => {
      expect(wrapper.text()).not.toContain(TEST_EDITOR_POSITION);
    });
  });

  it('renders terminal sync status', () => {
    createComponent();

    expect(wrapper.findComponent(TerminalSyncStatusSafe).exists()).toBe(true);
  });
});

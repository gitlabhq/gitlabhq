import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import IdeStatusList from '~/ide/components/ide_status_list';

const TEST_FILE = {
  name: 'lorem.md',
  eol: 'LF',
  editorRow: 3,
  editorColumn: 23,
  fileLanguage: 'markdown',
};

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ide/components/ide_status_list', () => {
  let activeFile;
  let store;
  let wrapper;

  const createComponent = (options = {}) => {
    store = new Vuex.Store({
      getters: {
        activeFile: () => activeFile,
      },
    });

    wrapper = shallowMount(IdeStatusList, {
      localVue,
      sync: false,
      store,
      ...options,
    });
  };

  beforeEach(() => {
    activeFile = TEST_FILE;
  });

  afterEach(() => {
    wrapper.destroy();

    store = null;
    wrapper = null;
  });

  const getEditorPosition = file => `${file.editorRow}:${file.editorColumn}`;

  describe('with regular file', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows file name', () => {
      expect(wrapper.text()).toContain(TEST_FILE.name);
    });

    it('shows file eol', () => {
      expect(wrapper.text()).toContain(TEST_FILE.name);
    });

    it('shows file editor position', () => {
      expect(wrapper.text()).toContain(getEditorPosition(TEST_FILE));
    });

    it('shows file language', () => {
      expect(wrapper.text()).toContain(TEST_FILE.fileLanguage);
    });
  });

  describe('with binary file', () => {
    beforeEach(() => {
      activeFile.binary = true;
      createComponent();
    });

    it('does not show file editor position', () => {
      expect(wrapper.text()).not.toContain(getEditorPosition(TEST_FILE));
    });
  });

  it('adds slot as child of list', () => {
    createComponent({
      slots: {
        default: ['<div class="js-test">Hello</div>', '<div class="js-test">World</div>'],
      },
    });

    expect(wrapper.find('.ide-status-list').findAll('.js-test').length).toEqual(2);
  });
});

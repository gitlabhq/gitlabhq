import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import App from '~/code_navigation/components/app.vue';
import Popover from '~/code_navigation/components/popover.vue';
import createState from '~/code_navigation/store/state';

const setInitialData = jest.fn();
const fetchData = jest.fn();
const showDefinition = jest.fn();
let wrapper;

Vue.use(Vuex);

function factory(initialState = {}, props = {}) {
  const store = new Vuex.Store({
    state: {
      ...createState(),
      ...initialState,
      definitionPathPrefix: 'https://test.com/blob/main',
    },
    actions: {
      setInitialData,
      fetchData,
      showDefinition,
    },
  });

  wrapper = shallowMount(App, { store, propsData: { ...props } });
}

describe('Code navigation app component', () => {
  it('sets initial data on mount if the correct props are passed', () => {
    const codeNavigationPath = 'code/nav/path.js';
    const path = 'blob/path.js';
    const definitionPathPrefix = 'path/prefix';
    const wrapTextNodes = true;

    factory(
      {},
      { codeNavigationPath, blobPath: path, pathPrefix: definitionPathPrefix, wrapTextNodes },
    );

    expect(setInitialData).toHaveBeenCalledWith(expect.anything(), {
      blobs: [{ codeNavigationPath, path }],
      definitionPathPrefix,
      wrapTextNodes,
    });
  });

  it('fetches data on mount', () => {
    factory();

    expect(fetchData).toHaveBeenCalled();
  });

  it('hides popover when no definition set', () => {
    factory();

    expect(wrapper.findComponent(Popover).exists()).toBe(false);
  });

  it('renders popover when definition set', () => {
    factory({
      currentDefinition: { hover: 'console' },
      currentDefinitionPosition: { x: 0 },
      currentBlobPath: 'index.js',
    });

    expect(wrapper.findComponent(Popover).exists()).toBe(true);
  });

  it('calls showDefinition when clicking blob viewer', () => {
    setHTMLFixture('<div class="blob-viewer"></div>');

    factory();

    document.querySelector('.blob-viewer').click();

    expect(showDefinition).toHaveBeenCalled();

    resetHTMLFixture();
  });
});

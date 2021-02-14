import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import component from '~/blob/notebook/notebook_viewer.vue';
import axios from '~/lib/utils/axios_utils';
import NotebookLab from '~/notebook/index.vue';

describe('iPython notebook renderer', () => {
  let wrapper;
  let mock;

  const endpoint = 'test';
  const mockNotebook = {
    cells: [
      {
        cell_type: 'markdown',
        source: ['# test'],
      },
      {
        cell_type: 'code',
        execution_count: 1,
        source: ['def test(str)', '  return str'],
        outputs: [],
      },
    ],
  };

  const mountComponent = () => {
    wrapper = shallowMount(component, { propsData: { endpoint } });
  };

  const findLoading = () => wrapper.find(GlLoadingIcon);
  const findNotebookLab = () => wrapper.find(NotebookLab);
  const findLoadErrorMessage = () => wrapper.find({ ref: 'loadErrorMessage' });
  const findParseErrorMessage = () => wrapper.find({ ref: 'parsingErrorMessage' });

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mock.restore();
  });

  it('shows loading icon', () => {
    mock.onGet(endpoint).reply(() => new Promise(() => {}));
    mountComponent({ loadFile: jest.fn() });
    expect(findLoading().exists()).toBe(true);
  });

  describe('successful response', () => {
    beforeEach(() => {
      mock.onGet(endpoint).reply(200, mockNotebook);
      mountComponent();
      return waitForPromises();
    });

    it('does not show loading icon', () => {
      expect(findLoading().exists()).toBe(false);
    });

    it('renders the notebook', () => {
      expect(findNotebookLab().exists()).toBe(true);
    });
  });

  describe('error in JSON response', () => {
    beforeEach(() => {
      mock.onGet(endpoint).reply(() =>
        // eslint-disable-next-line prefer-promise-reject-errors
        Promise.reject({ status: 200 }),
      );

      mountComponent();
      return waitForPromises();
    });

    it('does not show loading icon', () => {
      expect(findLoading().exists()).toBe(false);
    });

    it('shows error message', () => {
      expect(findParseErrorMessage().text()).toEqual('An error occurred while parsing the file.');
    });
  });

  describe('error getting file', () => {
    beforeEach(() => {
      mock.onGet(endpoint).reply(500, '');

      mountComponent();
      return waitForPromises();
    });

    it('does not show loading icon', () => {
      expect(findLoading().exists()).toBe(false);
    });

    it('shows error message', () => {
      expect(findLoadErrorMessage().text()).toEqual(
        'An error occurred while loading the file. Please try again later.',
      );
    });
  });
});

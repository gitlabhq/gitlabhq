import { GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { TEST_HOST as FAKE_ENDPOINT } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import ArtifactsListApp from '~/vue_merge_request_widget/components/artifacts_list_app.vue';
import { getStoreConfig } from '~/vue_merge_request_widget/stores/artifacts_list';
import { artifacts } from '../mock_data';

Vue.use(Vuex);

describe('Merge Requests Artifacts list app', () => {
  let wrapper;
  let store;
  let mock;

  const actionSpies = {
    fetchArtifacts: jest.fn(),
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  const createComponent = () => {
    const storeConfig = getStoreConfig();
    store = new Vuex.Store({
      ...storeConfig,
      actions: {
        ...storeConfig.actions,
        ...actionSpies,
      },
    });

    wrapper = mount(ArtifactsListApp, {
      propsData: {
        endpoint: FAKE_ENDPOINT,
      },
      store,
    });
  };

  const findButtons = () => wrapper.findAll('button');
  const findTitle = () => wrapper.find('[data-testid="mr-collapsible-title"]');
  const findErrorMessage = () => wrapper.find('.js-error-state');
  const findTableRows = () => wrapper.findAll('tbody tr');

  describe('while loading', () => {
    beforeEach(() => {
      createComponent();
      store.dispatch('requestArtifacts');
      return nextTick();
    });

    it('renders a loading icon', () => {
      const loadingIcon = wrapper.find(GlLoadingIcon);
      expect(loadingIcon.exists()).toBe(true);
    });

    it('renders loading text', () => {
      expect(findTitle().text()).toBe('Loading artifacts');
    });

    it('renders disabled buttons', () => {
      const buttons = findButtons();
      expect(buttons.at(0).attributes('disabled')).toBe('disabled');
      expect(buttons.at(1).attributes('disabled')).toBe('disabled');
    });
  });

  describe('with results', () => {
    beforeEach(() => {
      createComponent();
      mock.onGet(FAKE_ENDPOINT).reply(200, artifacts, {});
      store.dispatch('receiveArtifactsSuccess', {
        data: artifacts,
        status: 200,
      });
      return nextTick();
    });

    it('renders a title with the number of artifacts', () => {
      expect(findTitle().text()).toBe('View 2 exposed artifacts');
    });

    it('renders both buttons enabled', () => {
      const buttons = findButtons();
      expect(buttons.at(0).attributes('disabled')).toBe(undefined);
      expect(buttons.at(1).attributes('disabled')).toBe(undefined);
    });

    describe('on click', () => {
      it('renders the list of artifacts', async () => {
        findTitle().trigger('click');
        await nextTick();

        expect(findTableRows().length).toEqual(2);
      });
    });
  });

  describe('with error', () => {
    beforeEach(() => {
      createComponent();
      mock.onGet(FAKE_ENDPOINT).reply(500, {}, {});
      store.dispatch('receiveArtifactsError');
      return nextTick();
    });

    it('renders the error state', () => {
      expect(findErrorMessage().text()).toBe('An error occurred while fetching the artifacts');
    });

    it('does not render buttons', () => {
      const buttons = findButtons();
      expect(buttons.exists()).toBe(false);
    });
  });
});

import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import MockAdapter from 'axios-mock-adapter';
import { GlLoadingIcon } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import ArtifactsListApp from '~/vue_merge_request_widget/components/artifacts_list_app.vue';
import createStore from '~/vue_merge_request_widget/stores/artifacts_list';
import { artifactsList } from './mock_data';

describe('Merge Requests Artifacts list app', () => {
  let wrapper;
  let mock;
  const store = createStore();
  const localVue = createLocalVue();
  localVue.use(Vuex);

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
    wrapper = mount(ArtifactsListApp, {
      propsData: {
        endpoint: TEST_HOST,
      },
      store,
      methods: {
        ...actionSpies,
      },
      localVue,
      sync: false,
    });
  };

  const findButtons = () => wrapper.findAll('button');
  const findTitle = () => wrapper.find('.js-title');
  const findErrorMessage = () => wrapper.find('.js-error-state');
  const findTableRows = () => wrapper.findAll('tbody tr');

  describe('while loading', () => {
    beforeEach(() => {
      createComponent();
      store.dispatch('requestArtifacts');
      return wrapper.vm.$nextTick();
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
      mock.onGet(wrapper.vm.$store.state.endpoint).reply(200, artifactsList, {});
      store.dispatch('receiveArtifactsSuccess', {
        data: artifactsList,
        status: 200,
      });
      return wrapper.vm.$nextTick();
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
      it('renders the list of artifacts', () => {
        findTitle().trigger('click');
        wrapper.vm.$nextTick(() => {
          expect(findTableRows().length).toEqual(2);
        });
      });
    });
  });

  describe('with error', () => {
    beforeEach(() => {
      createComponent();
      mock.onGet(wrapper.vm.$store.state.endpoint).reply(500, {}, {});
      store.dispatch('receiveArtifactsError');
      return wrapper.vm.$nextTick();
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

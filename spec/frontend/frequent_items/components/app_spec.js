import { GlButton, GlIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import App from '~/frequent_items/components/app.vue';
import FrequentItemsList from '~/frequent_items/components/frequent_items_list.vue';
import { FREQUENT_ITEMS, FIFTEEN_MINUTES_IN_MS } from '~/frequent_items/constants';
import eventHub from '~/frequent_items/event_hub';
import { createStore } from '~/frequent_items/store';
import { getTopFrequentItems } from '~/frequent_items/utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { currentSession, mockFrequentProjects, mockSearchedProjects } from '../mock_data';

Vue.use(Vuex);

useLocalStorageSpy();

const TEST_NAMESPACE = 'projects';
const TEST_VUEX_MODULE = 'frequentProjects';
const TEST_PROJECT = currentSession[TEST_NAMESPACE].project;
const TEST_STORAGE_KEY = currentSession[TEST_NAMESPACE].storageKey;
const TEST_SEARCH_CLASS = 'test-search-class';

describe('Frequent Items App Component', () => {
  let wrapper;
  let mock;
  let store;

  const createComponent = (props = {}) => {
    const session = currentSession[TEST_NAMESPACE];
    gon.api_version = session.apiVersion;

    wrapper = mountExtended(App, {
      store,
      propsData: {
        namespace: TEST_NAMESPACE,
        currentUserName: session.username,
        currentItem: session.project,
        ...props,
      },
      provide: {
        vuexModule: TEST_VUEX_MODULE,
      },
    });
  };

  const triggerDropdownOpen = () => eventHub.$emit(`${TEST_NAMESPACE}-dropdownOpen`);
  const getStoredProjects = () => JSON.parse(localStorage.getItem(TEST_STORAGE_KEY));
  const findSearchInput = () => wrapper.findByTestId('frequent-items-search-input');
  const findLoading = () => wrapper.findByTestId('loading');
  const findSectionHeader = () => wrapper.findByTestId('header');
  const findFrequentItemsList = () => wrapper.findComponent(FrequentItemsList);
  const findFrequentItems = () => findFrequentItemsList().findAll('li');
  const setSearch = (search) => {
    const searchInput = wrapper.find('input');

    searchInput.setValue(search);
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    store = createStore();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('default', () => {
    beforeEach(() => {
      jest.spyOn(store, 'dispatch');

      createComponent();
    });

    it('should fetch frequent items', () => {
      triggerDropdownOpen();

      expect(store.dispatch).toHaveBeenCalledWith(`${TEST_VUEX_MODULE}/fetchFrequentItems`);
    });

    it('should not fetch frequent items if detroyed', () => {
      wrapper.destroy();
      triggerDropdownOpen();

      expect(store.dispatch).not.toHaveBeenCalledWith(`${TEST_VUEX_MODULE}/fetchFrequentItems`);
    });

    it('should render search input', () => {
      expect(findSearchInput().classes()).toEqual(['search-input-container']);
    });

    it('should render loading animation', async () => {
      triggerDropdownOpen();
      store.state[TEST_VUEX_MODULE].isLoadingItems = true;

      await nextTick();

      const loading = findLoading();

      expect(loading.exists()).toBe(true);
      expect(loading.find('[aria-label="Loading projects"]').exists()).toBe(true);
      expect(findSectionHeader().exists()).toBe(false);
    });

    it('should render frequent projects list header', () => {
      const sectionHeader = findSectionHeader();

      expect(sectionHeader.exists()).toBe(true);
      expect(sectionHeader.text()).toBe('Frequently visited');
    });

    it('should render searched projects list', async () => {
      mock
        .onGet(/\/api\/v4\/projects.json(.*)$/)
        .replyOnce(HTTP_STATUS_OK, mockSearchedProjects.data);

      setSearch('gitlab');
      await nextTick();

      expect(findLoading().exists()).toBe(true);

      await waitForPromises();

      expect(findFrequentItems().length).toBe(mockSearchedProjects.data.length);
      expect(findFrequentItemsList().props()).toEqual(
        expect.objectContaining({
          items: mockSearchedProjects.data.map(
            ({
              avatar_url: avatarUrl,
              web_url: webUrl,
              name_with_namespace: namespace,
              ...item
            }) => ({
              ...item,
              avatarUrl,
              webUrl,
              namespace,
            }),
          ),
          namespace: TEST_NAMESPACE,
          hasSearchQuery: true,
          isFetchFailed: false,
          matcher: 'gitlab',
        }),
      );
    });

    describe('with frequent items list', () => {
      const expectedResult = getTopFrequentItems(mockFrequentProjects);

      beforeEach(async () => {
        localStorage.setItem(TEST_STORAGE_KEY, JSON.stringify(mockFrequentProjects));
        triggerDropdownOpen();
        await nextTick();
      });

      it('should render edit button within header', () => {
        const itemEditButton = findSectionHeader().findComponent(GlButton);

        expect(itemEditButton.exists()).toBe(true);
        expect(itemEditButton.attributes('title')).toBe('Toggle edit mode');
        expect(itemEditButton.findComponent(GlIcon).props('name')).toBe('pencil');
      });

      it('should render frequent projects list', () => {
        expect(findFrequentItems().length).toBe(expectedResult.length);
        expect(findFrequentItemsList().props()).toEqual({
          items: expectedResult,
          namespace: TEST_NAMESPACE,
          hasSearchQuery: false,
          isFetchFailed: false,
          isItemRemovalFailed: false,
          matcher: '',
        });
      });

      it('dispatches action `toggleItemsListEditablity` when edit button is clicked', async () => {
        const itemEditButton = findSectionHeader().findComponent(GlButton);
        itemEditButton.vm.$emit('click');

        await nextTick();

        expect(store.dispatch).toHaveBeenCalledWith(
          `${TEST_VUEX_MODULE}/toggleItemsListEditablity`,
        );
      });
    });
  });

  describe('with searchClass', () => {
    beforeEach(() => {
      createComponent({ searchClass: TEST_SEARCH_CLASS });
    });

    it('should render search input with searchClass', () => {
      expect(findSearchInput().classes()).toEqual(['search-input-container', TEST_SEARCH_CLASS]);
    });
  });

  describe('logging', () => {
    it('when created, it should create a project storage entry and adds a project', () => {
      createComponent();

      expect(getStoredProjects()).toEqual([
        expect.objectContaining({
          frequency: 1,
          lastAccessedOn: Date.now(),
        }),
      ]);
    });

    describe('when created multiple times', () => {
      beforeEach(() => {
        createComponent();
        wrapper.destroy();
        createComponent();
        wrapper.destroy();
      });

      it('should only log once', () => {
        expect(getStoredProjects()).toEqual([
          expect.objectContaining({
            lastAccessedOn: Date.now(),
            frequency: 1,
          }),
        ]);
      });

      it('should increase frequency, when created 15 minutes later', () => {
        const fifteenMinutesLater = Date.now() + FIFTEEN_MINUTES_IN_MS + 1;

        jest.spyOn(Date, 'now').mockReturnValue(fifteenMinutesLater);
        createComponent({ currentItem: { ...TEST_PROJECT, lastAccessedOn: fifteenMinutesLater } });

        expect(getStoredProjects()).toEqual([
          expect.objectContaining({
            lastAccessedOn: fifteenMinutesLater,
            frequency: 2,
          }),
        ]);
      });
    });

    it('should always update project metadata', () => {
      const oldProject = {
        ...TEST_PROJECT,
      };

      const newProject = {
        ...oldProject,
        name: 'New Name',
        avatarUrl: 'new/avatar.png',
        namespace: 'New / Namespace',
        webUrl: 'http://localhost/new/web/url',
      };

      createComponent({ currentItem: oldProject });
      wrapper.destroy();
      expect(getStoredProjects()).toEqual([expect.objectContaining(oldProject)]);

      createComponent({ currentItem: newProject });
      wrapper.destroy();

      expect(getStoredProjects()).toEqual([expect.objectContaining(newProject)]);
    });

    it('should not add more than 20 projects in store', () => {
      for (let id = 0; id < FREQUENT_ITEMS.MAX_COUNT + 10; id += 1) {
        const project = {
          ...TEST_PROJECT,
          id,
        };
        createComponent({ currentItem: project });
        wrapper.destroy();
      }

      expect(getStoredProjects().length).toBe(FREQUENT_ITEMS.MAX_COUNT);
    });
  });
});

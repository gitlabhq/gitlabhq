import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { TEST_HOST } from 'helpers/test_constants';
import createEventHub from '~/helpers/event_hub_factory';
import * as urlUtility from '~/lib/utils/url_utility';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import DiscussionFilter from '~/notes/components/discussion_filter.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import Tracking from '~/tracking';
import {
  DISCUSSION_FILTERS_DEFAULT_VALUE,
  DISCUSSION_FILTER_TYPES,
  ASC,
  DESC,
} from '~/notes/constants';
import notesModule from '~/notes/stores/modules';

import { discussionFiltersMock, discussionMock } from '../mock_data';

Vue.use(Vuex);

const DISCUSSION_PATH = `${TEST_HOST}/example`;

describe('DiscussionFilter component', () => {
  let wrapper;
  let store;
  let eventHub;
  let mock;

  const filterDiscussion = jest.fn();

  const findFilter = (filterType) =>
    wrapper.find(`.gl-new-dropdown-item[data-filter-type="${filterType}"]`);
  const findGlDisclosureDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);

  const mountComponent = ({ propsData = {} } = {}) => {
    const discussions = [
      {
        ...discussionMock,
        id: discussionMock.id,
        notes: [{ ...discussionMock.notes[0], resolvable: true, resolved: true }],
      },
    ];

    const defaultStore = { ...notesModule() };

    store = new Vuex.Store({
      ...defaultStore,
      actions: {
        ...defaultStore.actions,
        filterDiscussion,
      },
    });

    store.state.notesData.discussionsPath = DISCUSSION_PATH;

    store.state.discussions = discussions;

    wrapper = mount(DiscussionFilter, {
      store,
      propsData: {
        filters: discussionFiltersMock,
        selectedValue: DISCUSSION_FILTERS_DEFAULT_VALUE,
        ...propsData,
      },
    });
  };

  beforeEach(() => {
    mock = new AxiosMockAdapter(axios);

    // We are mocking the discussions retrieval,
    // as it doesn't matter for our tests here
    mock.onGet(DISCUSSION_PATH).reply(HTTP_STATUS_OK, '');
    window.mrTabs = undefined;
    jest.spyOn(Tracking, 'event');
  });

  afterEach(() => {
    mock.restore();
  });

  describe('default', () => {
    beforeEach(() => {
      mountComponent();
      jest.spyOn(store, 'dispatch').mockImplementation();
    });

    it('has local storage sync with the correct props', () => {
      expect(findLocalStorageSync().props('asString')).toBe(true);
    });

    it('calls setDiscussionSortDirection when update is emitted', () => {
      findLocalStorageSync().vm.$emit('input', ASC);

      expect(store.dispatch).toHaveBeenCalledWith('setDiscussionSortDirection', { direction: ASC });
    });
  });

  describe('when asc', () => {
    beforeEach(() => {
      mountComponent();
      jest.spyOn(store, 'dispatch').mockImplementation();
    });

    describe('when the dropdown is clicked', () => {
      it('calls the right actions', () => {
        wrapper.find('.js-newest-first').vm.$emit('action');

        expect(store.dispatch).toHaveBeenCalledWith('setDiscussionSortDirection', {
          direction: DESC,
        });
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'change_discussion_sort_direction', {
          property: DESC,
        });
      });
    });
  });

  describe('when desc', () => {
    beforeEach(() => {
      mountComponent();
      store.state.discussionSortOrder = DESC;
      jest.spyOn(store, 'dispatch').mockImplementation();
    });

    describe('when the dropdown item is clicked', () => {
      it('calls the right actions', () => {
        wrapper.find('.js-oldest-first').vm.$emit('action');

        expect(store.dispatch).toHaveBeenCalledWith('setDiscussionSortDirection', {
          direction: ASC,
        });
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'change_discussion_sort_direction', {
          property: ASC,
        });
      });

      it('sets is-selected to true on the active button in the dropdown', () => {
        expect(findGlDisclosureDropdownItem().attributes('is-selected')).toBe('true');
      });
    });
  });

  describe('discussion filter functionality', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders the all filters', () => {
      expect(wrapper.findAll('.discussion-filter-container .gl-new-dropdown-item').length).toBe(
        discussionFiltersMock.length,
      );
    });

    it('renders the default selected item', () => {
      expect(wrapper.find('.discussion-filter-container .gl-new-dropdown-item').text().trim()).toBe(
        discussionFiltersMock[0].title,
      );
    });

    it('disables the dropdown when discussions are loading', () => {
      store.state.isLoading = true;

      expect(wrapper.findComponent(GlDisclosureDropdown).props('disabled')).toBe(true);
    });

    it('updates to the selected item', () => {
      const filterItem = findFilter(DISCUSSION_FILTER_TYPES.ALL);

      filterItem.vm.$emit('action');

      expect(filterItem.text().trim()).toBe('Show all activity');
    });

    it('only updates when selected filter changes', () => {
      findFilter(DISCUSSION_FILTER_TYPES.ALL).vm.$emit('action');

      expect(filterDiscussion).not.toHaveBeenCalled();
    });

    it('disables timeline view if it was enabled', () => {
      store.state.isTimelineEnabled = true;

      findFilter(DISCUSSION_FILTER_TYPES.HISTORY).vm.$emit('action');

      expect(store.state.isTimelineEnabled).toBe(false);
    });

    it('disables commenting when "Show history only" filter is applied', () => {
      findFilter(DISCUSSION_FILTER_TYPES.HISTORY).vm.$emit('action');

      expect(store.state.commentsDisabled).toBe(true);
    });

    it('enables commenting when "Show history only" filter is not applied', () => {
      findFilter(DISCUSSION_FILTER_TYPES.ALL).vm.$emit('action');

      expect(store.state.commentsDisabled).toBe(false);
    });
  });

  describe('Merge request tabs', () => {
    eventHub = createEventHub();

    beforeEach(() => {
      window.mrTabs = {
        eventHub,
        currentTab: 'show',
      };

      mountComponent();
    });

    afterEach(() => {
      window.mrTabs = undefined;
    });

    it('only renders when discussion tab is active', async () => {
      eventHub.$emit('MergeRequestTabChange', 'commit');

      await nextTick();
      expect(wrapper.find('*').exists()).toBe(false);
    });
  });

  describe('URL with Links to notes', () => {
    const findGlDisclosureDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);

    afterEach(() => {
      window.location.hash = '';
    });

    it('does not update the filter when the current filter is "Show all activity"', async () => {
      window.location.hash = `note_${discussionMock.notes[0].id}`;
      mountComponent();

      await nextTick();
      const filtered = findGlDisclosureDropdownItems().filter((el) => el.classes('is-active'));

      expect(filtered).toHaveLength(1);
      expect(filtered.at(0).text()).toBe(discussionFiltersMock[0].title);
    });

    it('only updates filter when the URL links to a note', async () => {
      window.location.hash = `testing123`;
      mountComponent();

      await nextTick();
      const filtered = findGlDisclosureDropdownItems().filter((el) => el.classes('is-active'));

      expect(filtered).toHaveLength(1);
      expect(filtered.at(0).text()).toBe(discussionFiltersMock[0].title);
    });

    it('does not fetch discussions when there is no hash', async () => {
      mountComponent();
      const dispatchSpy = jest.spyOn(store, 'dispatch');

      await nextTick();
      expect(dispatchSpy).not.toHaveBeenCalled();
    });

    describe('selected value is not default state', () => {
      beforeEach(() => {
        mountComponent({
          propsData: { selectedValue: 2 },
        });
      });
      it('fetch discussions when there is hash', async () => {
        jest.spyOn(urlUtility, 'getLocationHash').mockReturnValueOnce('note_123');
        const dispatchSpy = jest.spyOn(store, 'dispatch');

        window.dispatchEvent(new Event('hashchange'));

        await nextTick();
        expect(dispatchSpy).toHaveBeenCalledWith('filterDiscussion', {
          filter: 0,
          path: 'http://test.host/example',
          persistFilter: false,
        });
      });
    });
  });
});

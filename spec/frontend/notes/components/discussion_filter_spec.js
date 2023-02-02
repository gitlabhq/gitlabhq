import { GlDropdown } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import { TEST_HOST } from 'helpers/test_constants';
import createEventHub from '~/helpers/event_hub_factory';

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
    wrapper.find(`.dropdown-item[data-filter-type="${filterType}"]`);

  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);

  const mountComponent = () => {
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

    return mount(DiscussionFilter, {
      store,
      propsData: {
        filters: discussionFiltersMock,
        selectedValue: DISCUSSION_FILTERS_DEFAULT_VALUE,
      },
    });
  };

  beforeEach(() => {
    mock = new AxiosMockAdapter(axios);

    // We are mocking the discussions retrieval,
    // as it doesn't matter for our tests here
    mock.onGet(DISCUSSION_PATH).reply(HTTP_STATUS_OK, '');
    window.mrTabs = undefined;
    wrapper = mountComponent();
    jest.spyOn(Tracking, 'event');
  });

  afterEach(() => {
    wrapper.vm.$destroy();
    mock.restore();
  });

  describe('default', () => {
    beforeEach(() => {
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
      jest.spyOn(store, 'dispatch').mockImplementation();
    });

    describe('when the dropdown is clicked', () => {
      it('calls the right actions', () => {
        wrapper.find('.js-newest-first').vm.$emit('click');

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
      store.state.discussionSortOrder = DESC;
      jest.spyOn(store, 'dispatch').mockImplementation();
    });

    describe('when the dropdown item is clicked', () => {
      it('calls the right actions', () => {
        wrapper.find('.js-oldest-first').vm.$emit('click');

        expect(store.dispatch).toHaveBeenCalledWith('setDiscussionSortDirection', {
          direction: ASC,
        });
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'change_discussion_sort_direction', {
          property: ASC,
        });
      });

      it('sets is-checked to true on the active button in the dropdown', () => {
        expect(wrapper.find('.js-newest-first').props('isChecked')).toBe(true);
      });
    });
  });

  it('renders the all filters', () => {
    expect(wrapper.findAll('.discussion-filter-container .dropdown-item').length).toBe(
      discussionFiltersMock.length,
    );
  });

  it('renders the default selected item', () => {
    expect(wrapper.find('.discussion-filter-container .dropdown-item').text().trim()).toBe(
      discussionFiltersMock[0].title,
    );
  });

  it('disables the dropdown when discussions are loading', () => {
    store.state.isLoading = true;

    expect(wrapper.findComponent(GlDropdown).props('disabled')).toBe(true);
  });

  it('updates to the selected item', () => {
    const filterItem = findFilter(DISCUSSION_FILTER_TYPES.ALL);

    filterItem.trigger('click');

    expect(wrapper.vm.currentFilter.title).toBe(filterItem.text().trim());
  });

  it('only updates when selected filter changes', () => {
    findFilter(DISCUSSION_FILTER_TYPES.ALL).trigger('click');

    expect(filterDiscussion).not.toHaveBeenCalled();
  });

  it('disables timeline view if it was enabled', () => {
    store.state.isTimelineEnabled = true;

    findFilter(DISCUSSION_FILTER_TYPES.HISTORY).trigger('click');

    expect(wrapper.vm.$store.state.isTimelineEnabled).toBe(false);
  });

  it('disables commenting when "Show history only" filter is applied', () => {
    findFilter(DISCUSSION_FILTER_TYPES.HISTORY).trigger('click');

    expect(wrapper.vm.$store.state.commentsDisabled).toBe(true);
  });

  it('enables commenting when "Show history only" filter is not applied', () => {
    findFilter(DISCUSSION_FILTER_TYPES.ALL).trigger('click');

    expect(wrapper.vm.$store.state.commentsDisabled).toBe(false);
  });

  describe('Merge request tabs', () => {
    eventHub = createEventHub();

    beforeEach(() => {
      window.mrTabs = {
        eventHub,
        currentTab: 'show',
      };

      wrapper = mountComponent();
    });

    afterEach(() => {
      window.mrTabs = undefined;
    });

    it('only renders when discussion tab is active', async () => {
      eventHub.$emit('MergeRequestTabChange', 'commit');

      await nextTick();
      expect(wrapper.html()).toBe('');
    });
  });

  describe('URL with Links to notes', () => {
    afterEach(() => {
      window.location.hash = '';
    });

    it('updates the filter when the URL links to a note', async () => {
      window.location.hash = `note_${discussionMock.notes[0].id}`;
      wrapper.vm.currentValue = discussionFiltersMock[2].value;
      wrapper.vm.handleLocationHash();

      await nextTick();
      expect(wrapper.vm.currentValue).toBe(DISCUSSION_FILTERS_DEFAULT_VALUE);
    });

    it('does not update the filter when the current filter is "Show all activity"', async () => {
      window.location.hash = `note_${discussionMock.notes[0].id}`;
      wrapper.vm.handleLocationHash();

      await nextTick();
      expect(wrapper.vm.currentValue).toBe(DISCUSSION_FILTERS_DEFAULT_VALUE);
    });

    it('only updates filter when the URL links to a note', async () => {
      window.location.hash = `testing123`;
      wrapper.vm.handleLocationHash();

      await nextTick();
      expect(wrapper.vm.currentValue).toBe(DISCUSSION_FILTERS_DEFAULT_VALUE);
    });

    it('fetches discussions when there is a hash', async () => {
      window.location.hash = `note_${discussionMock.notes[0].id}`;
      wrapper.vm.currentValue = discussionFiltersMock[2].value;
      jest.spyOn(wrapper.vm, 'selectFilter').mockImplementation(() => {});
      wrapper.vm.handleLocationHash();

      await nextTick();
      expect(wrapper.vm.selectFilter).toHaveBeenCalled();
    });

    it('does not fetch discussions when there is no hash', async () => {
      window.location.hash = '';
      jest.spyOn(wrapper.vm, 'selectFilter').mockImplementation(() => {});
      wrapper.vm.handleLocationHash();

      await nextTick();
      expect(wrapper.vm.selectFilter).not.toHaveBeenCalled();
    });
  });
});

import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import SortDiscussion from '~/notes/components/sort_discussion.vue';
import { ASC, DESC } from '~/notes/constants';
import createStore from '~/notes/stores';
import Tracking from '~/tracking';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Sort Discussion component', () => {
  let wrapper;
  let store;

  const createComponent = () => {
    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(SortDiscussion, {
      localVue,
      store,
    });
  };

  const findLocalStorageSync = () => wrapper.find(LocalStorageSync);

  beforeEach(() => {
    store = createStore();
    jest.spyOn(Tracking, 'event');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has local storage sync', () => {
      expect(findLocalStorageSync().exists()).toBe(true);
    });

    it('calls setDiscussionSortDirection when update is emitted', () => {
      findLocalStorageSync().vm.$emit('input', ASC);

      expect(store.dispatch).toHaveBeenCalledWith('setDiscussionSortDirection', { direction: ASC });
    });
  });

  describe('when asc', () => {
    describe('when the dropdown is clicked', () => {
      it('calls the right actions', () => {
        createComponent();

        wrapper.find('.js-newest-first').vm.$emit('click');

        expect(store.dispatch).toHaveBeenCalledWith('setDiscussionSortDirection', {
          direction: DESC,
        });
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'change_discussion_sort_direction', {
          property: DESC,
        });
      });
    });

    it('shows the "Oldest First" as the dropdown', () => {
      createComponent();

      expect(wrapper.find('.js-dropdown-text').props('text')).toBe('Oldest first');
    });
  });

  describe('when desc', () => {
    beforeEach(() => {
      store.state.discussionSortOrder = DESC;
      createComponent();
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

    it('shows the "Newest First" as the dropdown', () => {
      expect(wrapper.find('.js-dropdown-text').props('text')).toBe('Newest first');
    });
  });
});

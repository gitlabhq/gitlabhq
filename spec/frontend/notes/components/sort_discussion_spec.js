import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import SortDiscussion from '~/notes/components/sort_discussion.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import createStore from '~/notes/stores';
import { ASC, DESC } from '~/notes/constants';
import Tracking from '~/tracking';

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

      expect(store.dispatch).toHaveBeenCalledWith('setDiscussionSortDirection', ASC);
    });
  });

  describe('when asc', () => {
    describe('when the dropdown is clicked', () => {
      it('calls the right actions', () => {
        createComponent();

        wrapper.find('.js-newest-first').trigger('click');

        expect(store.dispatch).toHaveBeenCalledWith('setDiscussionSortDirection', DESC);
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'change_discussion_sort_direction', {
          property: DESC,
        });
      });
    });

    it('shows the "Oldest First" as the dropdown', () => {
      createComponent();

      expect(wrapper.find('.js-dropdown-text').text()).toBe('Oldest first');
    });
  });

  describe('when desc', () => {
    beforeEach(() => {
      store.state.discussionSortOrder = DESC;
      createComponent();
    });

    describe('when the dropdown item is clicked', () => {
      it('calls the right actions', () => {
        wrapper.find('.js-oldest-first').trigger('click');

        expect(store.dispatch).toHaveBeenCalledWith('setDiscussionSortDirection', ASC);
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'change_discussion_sort_direction', {
          property: ASC,
        });
      });

      it('applies the active class to the correct button in the dropdown', () => {
        expect(wrapper.find('.js-newest-first').classes()).toContain('is-active');
      });
    });

    it('shows the "Newest First" as the dropdown', () => {
      expect(wrapper.find('.js-dropdown-text').text()).toBe('Newest first');
    });
  });
});

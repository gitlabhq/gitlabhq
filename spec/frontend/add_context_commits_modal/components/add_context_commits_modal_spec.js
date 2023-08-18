import { GlModal, GlFilteredSearch } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import getDiffWithCommit from 'test_fixtures/merge_request_diffs/with_commit.json';
import AddReviewItemsModal from '~/add_context_commits_modal/components/add_context_commits_modal_wrapper.vue';

import * as actions from '~/add_context_commits_modal/store/actions';
import mutations from '~/add_context_commits_modal/store/mutations';
import defaultState from '~/add_context_commits_modal/store/state';

Vue.use(Vuex);

describe('AddContextCommitsModal', () => {
  let wrapper;
  let store;
  const createContextCommits = jest.fn();
  const removeContextCommits = jest.fn();
  const resetModalState = jest.fn();
  const searchCommits = jest.fn();
  const { commit } = getDiffWithCommit;

  const createWrapper = (props = {}) => {
    store = new Vuex.Store({
      mutations,
      state: {
        ...defaultState(),
      },
      actions: {
        ...actions,
        searchCommits,
        createContextCommits,
        removeContextCommits,
        resetModalState,
      },
    });

    wrapper = shallowMount(AddReviewItemsModal, {
      store,
      propsData: {
        contextCommitsPath: '',
        targetBranch: 'main',
        mergeRequestIid: 1,
        projectId: 1,
        ...props,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findSearch = () => wrapper.findComponent(GlFilteredSearch);

  beforeEach(() => {
    createWrapper();
  });

  it('renders modal with 2 tabs', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('an ok button labeled "Save changes"', () => {
    expect(findModal().attributes('ok-title')).toEqual('Save changes');
  });

  describe('when in first tab, renders a modal with', () => {
    it('renders the search box component', () => {
      expect(findSearch().exists()).toBe(true);
    });

    it('when user submits after entering filters in search box, then it calls action "searchCommits"', () => {
      const search = [
        'abcd',
        {
          type: 'author',
          value: { operator: '=', data: 'abhi' },
        },
        {
          type: 'committed-before-date',
          value: { operator: '=', data: '2022-10-31' },
        },
        {
          type: 'committed-after-date',
          value: { operator: '=', data: '2022-10-28' },
        },
      ];
      findSearch().vm.$emit('submit', search);
      expect(searchCommits).toHaveBeenCalledWith(expect.anything(), {
        searchText: 'abcd',
        author: 'abhi',
        committed_before: '2022-10-31',
        committed_after: '2022-10-28',
      });
    });

    it('disabled ok button when no row is selected', () => {
      expect(findModal().attributes('ok-disabled')).toBe('true');
    });

    it('enabled ok button when atleast one row is selected', async () => {
      store.state.selectedCommits = [{ ...commit, isSelected: true }];
      await nextTick();
      expect(findModal().attributes('ok-disabled')).toBe(undefined);
    });
  });

  describe('when in second tab, renders a modal with', () => {
    beforeEach(() => {
      store.state.tabIndex = 1;
    });
    it('a disabled ok button when no row is selected', () => {
      expect(findModal().attributes('ok-disabled')).toBe('true');
    });

    it('an enabled ok button when atleast one row is selected', async () => {
      store.state.selectedCommits = [{ ...commit, isSelected: true }];
      await nextTick();
      expect(findModal().attributes('ok-disabled')).toBe(undefined);
    });

    it('a disabled ok button in first tab, when row is selected in second tab', () => {
      createWrapper({ selectedContextCommits: [commit] });
      expect(wrapper.findComponent(GlModal).attributes('ok-disabled')).toBe('true');
    });
  });

  describe('has an ok button when clicked calls action', () => {
    it('"createContextCommits" when only new commits to be added', async () => {
      store.state.selectedCommits = [{ ...commit, isSelected: true }];
      findModal().vm.$emit('ok');
      await nextTick();
      expect(createContextCommits).toHaveBeenCalledWith(expect.anything(), {
        commits: [{ ...commit, isSelected: true }],
        forceReload: true,
      });
    });
    it('"removeContextCommits" when only added commits are to be removed', async () => {
      store.state.toRemoveCommits = [commit.short_id];
      findModal().vm.$emit('ok');
      await nextTick();
      expect(removeContextCommits).toHaveBeenCalledWith(expect.anything(), true);
    });
    it('"createContextCommits" and "removeContextCommits" when new commits are to be added and old commits are to be removed', async () => {
      store.state.selectedCommits = [{ ...commit, isSelected: true }];
      store.state.toRemoveCommits = [commit.short_id];
      findModal().vm.$emit('ok');
      await nextTick();
      expect(createContextCommits).toHaveBeenCalledWith(expect.anything(), {
        commits: [{ ...commit, isSelected: true }],
      });
      expect(removeContextCommits).toHaveBeenCalledWith(expect.anything(), undefined);
    });
  });

  describe('has a cancel button when clicked', () => {
    it('does not call "createContextCommits" or "removeContextCommits"', () => {
      findModal().vm.$emit('cancel');
      expect(createContextCommits).not.toHaveBeenCalled();
      expect(removeContextCommits).not.toHaveBeenCalled();
    });
    it('"resetModalState" to reset all the modal state', () => {
      findModal().vm.$emit('cancel');
      expect(resetModalState).toHaveBeenCalledWith(expect.anything(), undefined);
    });
  });

  describe('when model is closed by clicking the "X" button or by pressing "ESC" key', () => {
    it('does not call "createContextCommits" or "removeContextCommits"', () => {
      findModal().vm.$emit('close');
      expect(createContextCommits).not.toHaveBeenCalled();
      expect(removeContextCommits).not.toHaveBeenCalled();
    });
    it('"resetModalState" to reset all the modal state', () => {
      findModal().vm.$emit('close');
      expect(resetModalState).toHaveBeenCalledWith(expect.anything(), undefined);
    });
  });
});

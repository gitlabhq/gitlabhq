import { GlModal, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import AddReviewItemsModal from '~/add_context_commits_modal/components/add_context_commits_modal_wrapper.vue';

import * as actions from '~/add_context_commits_modal/store/actions';
import mutations from '~/add_context_commits_modal/store/mutations';
import defaultState from '~/add_context_commits_modal/store/state';
import getDiffWithCommit from '../../diffs/mock_data/diff_with_commit';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('AddContextCommitsModal', () => {
  let wrapper;
  let store;
  const createContextCommits = jest.fn();
  const removeContextCommits = jest.fn();
  const resetModalState = jest.fn();
  const searchCommits = jest.fn();
  const { commit } = getDiffWithCommit();

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
      localVue,
      store,
      propsData: {
        contextCommitsPath: '',
        targetBranch: 'main',
        mergeRequestIid: 1,
        projectId: 1,
        ...props,
      },
    });
    return wrapper;
  };

  const findModal = () => wrapper.find(GlModal);
  const findSearch = () => wrapper.find(GlSearchBoxByType);

  beforeEach(() => {
    wrapper = createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
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

    it('when user starts entering text in search box, it calls action "searchCommits" after waiting for 500s', () => {
      const searchText = 'abcd';
      findSearch().vm.$emit('input', searchText);
      expect(searchCommits).not.toBeCalled();
      jest.advanceTimersByTime(500);
      expect(searchCommits).toHaveBeenCalledWith(expect.anything(), searchText);
    });

    it('disabled ok button when no row is selected', () => {
      expect(findModal().attributes('ok-disabled')).toBe('true');
    });

    it('enabled ok button when atleast one row is selected', () => {
      wrapper.vm.$store.state.selectedCommits = [{ ...commit, isSelected: true }];
      return wrapper.vm.$nextTick().then(() => {
        expect(findModal().attributes('ok-disabled')).toBeFalsy();
      });
    });
  });

  describe('when in second tab, renders a modal with', () => {
    beforeEach(() => {
      wrapper.vm.$store.state.tabIndex = 1;
    });
    it('a disabled ok button when no row is selected', () => {
      expect(findModal().attributes('ok-disabled')).toBe('true');
    });

    it('an enabled ok button when atleast one row is selected', () => {
      wrapper.vm.$store.state.selectedCommits = [{ ...commit, isSelected: true }];
      return wrapper.vm.$nextTick().then(() => {
        expect(findModal().attributes('ok-disabled')).toBeFalsy();
      });
    });

    it('a disabled ok button in first tab, when row is selected in second tab', () => {
      createWrapper({ selectedContextCommits: [commit] });
      expect(wrapper.find(GlModal).attributes('ok-disabled')).toBe('true');
    });
  });

  describe('has an ok button when clicked calls action', () => {
    it('"createContextCommits" when only new commits to be added ', () => {
      wrapper.vm.$store.state.selectedCommits = [{ ...commit, isSelected: true }];
      findModal().vm.$emit('ok');
      return wrapper.vm.$nextTick().then(() => {
        expect(createContextCommits).toHaveBeenCalledWith(expect.anything(), {
          commits: [{ ...commit, isSelected: true }],
          forceReload: true,
        });
      });
    });
    it('"removeContextCommits" when only added commits are to be removed ', () => {
      wrapper.vm.$store.state.toRemoveCommits = [commit.short_id];
      findModal().vm.$emit('ok');
      return wrapper.vm.$nextTick().then(() => {
        expect(removeContextCommits).toHaveBeenCalledWith(expect.anything(), true);
      });
    });
    it('"createContextCommits" and "removeContextCommits" when new commits are to be added and old commits are to be removed', () => {
      wrapper.vm.$store.state.selectedCommits = [{ ...commit, isSelected: true }];
      wrapper.vm.$store.state.toRemoveCommits = [commit.short_id];
      findModal().vm.$emit('ok');
      return wrapper.vm.$nextTick().then(() => {
        expect(createContextCommits).toHaveBeenCalledWith(expect.anything(), {
          commits: [{ ...commit, isSelected: true }],
        });
        expect(removeContextCommits).toHaveBeenCalledWith(expect.anything(), undefined);
      });
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

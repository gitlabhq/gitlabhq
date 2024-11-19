import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EmptyState from '~/merge_requests/list/components/empty_state.vue';

describe('Merge request list app empty state component', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findByTestId('issuable-empty-state');
  const findNewMergeRequestLink = () => wrapper.findByTestId('new-merge-request-button');

  function createComponent(propsData = {}, provide = {}) {
    wrapper = shallowMountExtended(EmptyState, { propsData, provide });
  }

  it('renders new merge request link', () => {
    createComponent({}, { newMergeRequestPath: '/' });

    expect(findNewMergeRequestLink().exists()).toBe(true);
  });

  describe('when hasSearch is true', () => {
    it('sets the correct title and description', () => {
      createComponent({ hasSearch: true });

      expect(findEmptyState().attributes('title')).toBe('No results found');
      expect(findEmptyState().attributes('description')).toBe(
        'To widen your search, change or remove filters above.',
      );
    });
  });

  describe('when hasMergeRequests is false', () => {
    it('sets the correct title and description', () => {
      createComponent({ hasMergeRequests: false });

      expect(findEmptyState().attributes('title')).toBe(
        "Merge requests are a place to propose changes you've made to a project and discuss those changes with others",
      );
      expect(findEmptyState().attributes('description')).toBe(
        'Interested parties can even contribute by pushing commits if they want to.',
      );
    });
  });

  describe('when isOpenTab is true', () => {
    it('sets the correct title and description', () => {
      createComponent({ isOpenTab: true });

      expect(findEmptyState().attributes('title')).toBe('There are no open merge requests');
      expect(findEmptyState().attributes('description')).toBeUndefined();
    });
  });

  describe('when isOpenTab is false', () => {
    it('sets the correct title and description', () => {
      createComponent({ isOpenTab: false });

      expect(findEmptyState().attributes('title')).toBe('There are no closed merge requests');
      expect(findEmptyState().attributes('description')).toBeUndefined();
    });
  });
});

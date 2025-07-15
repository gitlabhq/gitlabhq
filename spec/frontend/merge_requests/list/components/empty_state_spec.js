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
        'Make a merge request to propose changes to this project.',
      );
      expect(findEmptyState().attributes('description')).toBe(
        'Others can contribute by pushing commits to the same branch.',
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

import RelatedIssuesBlock from '~/related_issues/components/related_issues_block.vue';
import ObservabilityRelatedIssues from '~/observability/components/observability_related_issues.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import { mockRelatedIssues } from '../mock_data';

jest.mock('~/alert');

describe('ObservabilityRelatedIssues', () => {
  let wrapper;

  const findRelatedIssuesBlock = () => wrapper.findComponent(RelatedIssuesBlock);

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(ObservabilityRelatedIssues, {
      propsData: {
        issues: [],
        fetchingIssues: false,
        error: null,
        helpPath: '/help-path',
        ...props,
      },
    });
  };

  describe('default behaviour', () => {
    beforeEach(() => createWrapper());

    it('renders the related issues block', () => {
      expect(findRelatedIssuesBlock().props()).toMatchObject({
        headerText: 'Related issues',
        helpPath: '/help-path',
        isFetching: false,
        relatedIssues: [],
        canAdmin: false,
        canReorder: false,
        isFormVisible: false,
        showCategorizedIssues: false,
        issuableType: 'issue',
        pathIdSeparator: '#',
      });
    });

    it('sets the related issues block empty message', () => {
      expect(findRelatedIssuesBlock().text()).toContain(
        'Create issues from this page to view them as related items here.',
      );
    });

    it('renders an alert container', () => {
      expect(wrapper.findByTestId('alert-container').classes()).toContain('flash-container');
    });

    it('does not call createAlert', () => {
      expect(createAlert).not.toHaveBeenCalled();
    });
  });

  describe('when fetchingIssues=true', () => {
    beforeEach(() => createWrapper({ fetchingIssues: true }));

    it('sets isFetching to true on the related issues block', () => {
      expect(findRelatedIssuesBlock().props()).toMatchObject({
        isFetching: true,
      });
    });
  });

  describe('when there are issues', () => {
    beforeEach(() => createWrapper({ issues: mockRelatedIssues }));

    it('sets the relatedIssues prop on the related issues block', () => {
      expect(findRelatedIssuesBlock().props()).toMatchObject({
        relatedIssues: mockRelatedIssues,
      });
    });
  });

  describe('when there is an error', () => {
    const error = new Error('Foo bar');

    beforeEach(() => createWrapper({ error }));

    it('calls createAlert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        error,
        message: 'Failed to load related issues. Try reloading the page.',
        parent: wrapper.vm.$el,
        captureError: true,
      });
    });
  });
});

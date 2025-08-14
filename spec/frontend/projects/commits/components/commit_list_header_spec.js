import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitListHeader from '~/projects/commits/components/commit_list_header.vue';
import CommitFilteredSearch from '~/projects/commits/components/commit_filtered_search.vue';
import CommitListBreadcrumb from '~/projects/commits/components/commit_list_breadcrumb.vue';
import RefSelector from '~/ref/components/ref_selector.vue';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('CommitListHeader', () => {
  let wrapper;

  const defaultProvide = {
    projectRootPath: 'gitlab-org/gitlab',
    projectId: '1',
    escapedRef: 'feature',
    refType: 'heads',
    rootRef: 'main',
  };

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(CommitListHeader, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  const findCommitFilteredSearch = () => wrapper.findComponent(CommitFilteredSearch);
  const findCommitListBreadcrumb = () => wrapper.findComponent(CommitListBreadcrumb);
  const findRefSelector = () => wrapper.findComponent(RefSelector);

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('renders the breadcrumb component', () => {
      expect(findCommitListBreadcrumb().exists()).toBe(true);
    });

    it('renders the page title', () => {
      expect(wrapper.find('h1').text()).toBe('Commits');
    });

    it('renders CommitFilteredSearch component', () => {
      expect(findCommitFilteredSearch().exists()).toBe(true);
    });

    it('renders RefSelector with correct props', () => {
      expect(findRefSelector().props()).toMatchObject({
        projectId: '1',
        useSymbolicRefNames: true,
        defaultBranch: 'main',
        queryParams: { sort: 'updated_desc' },
        value: 'refs/heads/feature',
      });
    });
  });

  describe('events', () => {
    it('emits filter event when CommitFilteredSearch emits filter', () => {
      const filterTokens = [{ type: 'author', value: { data: 'test-author' } }];

      findCommitFilteredSearch().vm.$emit('filter', filterTokens);

      expect(wrapper.emitted('filter')).toEqual([[filterTokens]]);
    });

    it('calls visitUrl with correct props when ref changes', () => {
      findRefSelector().vm.$emit('input', 'dev');
      expect(visitUrl).toHaveBeenCalledWith('http://test.host/gitlab-org/gitlab/-/tree/dev');
    });
  });
});

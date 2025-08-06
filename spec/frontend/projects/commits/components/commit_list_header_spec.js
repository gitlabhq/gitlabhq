import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitListHeader from '~/projects/commits/components/commit_list_header.vue';
import CommitFilteredSearch from '~/projects/commits/components/commit_filtered_search.vue';

describe('CommitListHeader', () => {
  let wrapper;

  const defaultProvide = {
    projectPath: 'gitlab-org/gitlab',
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

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('renders the page title', () => {
      expect(wrapper.find('h1').text()).toBe('Commits');
    });

    it('renders CommitFilteredSearch component', () => {
      expect(findCommitFilteredSearch().exists()).toBe(true);
    });
  });

  describe('events', () => {
    it('emits filter event when CommitFilteredSearch emits filter', () => {
      const filterTokens = [{ type: 'author', value: { data: 'test-author' } }];

      findCommitFilteredSearch().vm.$emit('filter', filterTokens);

      expect(wrapper.emitted('filter')).toEqual([[filterTokens]]);
    });
  });
});

import { shallowMount } from '@vue/test-utils';
import CommitListApp from '~/projects/commits/components/commit_list_app.vue';
import CommitListHeader from '~/projects/commits/components/commit_list_header.vue';

describe('Commit List App', () => {
  let wrapper;
  const createComponent = (provide = {}) => {
    wrapper = shallowMount(CommitListApp, {
      provide: {
        ...provide,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findCommitHeader = () => wrapper.findComponent(CommitListHeader);

  describe('commit header', () => {
    it('renders the commit header component', () => {
      expect(findCommitHeader().exists()).toBe(true);
    });
  });
});

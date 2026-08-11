import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitListRefSelector from '~/projects/commits/components/commit_list_ref_selector.vue';
import CommitListBreadcrumb from '~/projects/commits/components/commit_list_breadcrumb.vue';
import RefSelector from '~/vue_shared/components/ref/components/ref_selector.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('CommitListRefSelector', () => {
  let wrapper;

  const mockRouter = {
    push: jest.fn(),
  };

  const createComponent = ({
    filePath = 'README.md',
    currentRef = '',
    currentRefType = 'heads',
    routePath = '/dev/README.md',
    routeParams = {},
  } = {}) => {
    wrapper = shallowMountExtended(CommitListRefSelector, {
      provide: {
        projectId: '1',
        escapedRef: 'feature',
        rootRef: 'main',
      },
      propsData: {
        currentRef,
        currentRefType,
        filePath,
      },
      mocks: {
        $router: mockRouter,
        $route: {
          path: routePath,
          params: {
            path: filePath,
            ...routeParams,
          },
        },
      },
    });
  };

  const findCommitListBreadcrumb = () => wrapper.findComponent(CommitListBreadcrumb);
  const findRefSelector = () => wrapper.findComponent(RefSelector);

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('renders the breadcrumb component', () => {
      expect(findCommitListBreadcrumb().exists()).toBe(true);
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

    describe('refSelectorValue', () => {
      it('uses escapedRef when currentRef is not provided', () => {
        createComponent();
        expect(findRefSelector().props('value')).toBe('refs/heads/feature');
      });

      it('uses currentRef when provided', () => {
        createComponent({ currentRef: 'develop' });
        expect(findRefSelector().props('value')).toBe('refs/heads/develop');
      });

      it('uses currentRef without refType prefix when currentRefType is absent', () => {
        createComponent({ currentRef: 'develop', currentRefType: '' });
        expect(findRefSelector().props('value')).toBe('develop');
      });

      it('falls back to escapedRef when currentRef is empty string', () => {
        createComponent({ currentRef: '' });
        expect(findRefSelector().props('value')).toBe('refs/heads/feature');
      });

      it('updates the value when switching from a branch to a tag', async () => {
        createComponent({ currentRef: 'develop', currentRefType: 'heads' });
        expect(findRefSelector().props('value')).toBe('refs/heads/develop');

        await wrapper.setProps({ currentRef: 'v1.0', currentRefType: 'tags' });

        expect(findRefSelector().props('value')).toBe('refs/tags/v1.0');
      });
    });
  });

  describe('events', () => {
    it('updates router with correct props when ref changes', async () => {
      findRefSelector().vm.$emit('input', 'dev');
      await nextTick();

      expect(mockRouter.push).toHaveBeenCalledWith({
        path: '/dev/README.md',
        query: {},
      });
    });

    it('sets ref_type query param for symbolic refs', async () => {
      findRefSelector().vm.$emit('input', 'refs/tags/v1.0');
      await nextTick();

      expect(mockRouter.push).toHaveBeenCalledWith({
        path: '/v1.0/README.md',
        query: { ref_type: 'tags' },
      });
    });

    it('emits ref-change event with the actual ref name', async () => {
      findRefSelector().vm.$emit('input', 'refs/heads/new-branch');
      await nextTick();

      expect(wrapper.emitted('ref-change')).toEqual([['new-branch']]);
    });

    it('emits ref-change event with non-symbolic ref name', async () => {
      findRefSelector().vm.$emit('input', 'dev');
      await nextTick();

      expect(wrapper.emitted('ref-change')).toEqual([['dev']]);
    });

    it('properly encodes special characters in ref when updating router', async () => {
      findRefSelector().vm.$emit('input', 'feat/selected-#-ref-#');
      await nextTick();

      expect(mockRouter.push).toHaveBeenCalledWith({
        path: '/feat%2Fselected-%23-ref-%23/README.md',
        query: {},
      });
    });

    it('encodes slashes in ref so it becomes a single path segment', async () => {
      findRefSelector().vm.$emit('input', 'refs/heads/feature/my-branch');
      await nextTick();

      expect(mockRouter.push).toHaveBeenCalledWith({
        path: '/feature%2Fmy-branch/README.md',
        query: { ref_type: 'heads' },
      });
    });
  });
});

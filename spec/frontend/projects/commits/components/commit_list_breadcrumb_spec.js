import { GlBreadcrumb } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitListBreadcrumb from '~/projects/commits/components/commit_list_breadcrumb.vue';

describe('CommitListBreadcrumb', () => {
  let wrapper;

  const defaultProvide = {
    projectFullPath: 'gitlab-org/gitlab',
    projectPath: 'gitlab',
    escapedRef: 'main',
    refType: 'heads',
  };

  const createComponent = ({ provide = {}, path = 'README.md' } = {}) => {
    wrapper = shallowMountExtended(CommitListBreadcrumb, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      mocks: {
        $route: {
          params: {
            path,
          },
        },
      },
    });
  };

  const findBreadcrumb = () => wrapper.findComponent(GlBreadcrumb);

  beforeEach(() => {
    createComponent();
  });

  it('renders the GlBreadcrumb component with the correct props', () => {
    expect(findBreadcrumb().props()).toStrictEqual({
      ariaLabel: 'Commits breadcrumb',
      size: 'md',
      showMoreLabel: 'Show more breadcrumbs',
      autoResize: true,
      clipboardTooltipText: null,
      items: [
        {
          text: 'gitlab',
          to: '/main?ref_type=heads',
        },
        {
          text: 'README.md',
          to: '/main/README.md?ref_type=heads',
        },
      ],
      pathToCopy: null,
      showClipboardButton: false,
    });
  });

  describe('project root breadcrumb (no path)', () => {
    it('shows only project name for root path', () => {
      createComponent({ path: '' });

      const items = findBreadcrumb().props('items');

      expect(items).toStrictEqual([
        {
          text: 'gitlab',
          to: '/main?ref_type=heads',
        },
      ]);
    });
  });

  describe('handles different refs', () => {
    it('shows correct ref and ref type', () => {
      createComponent({
        provide: { escapedRef: 'v1.0', refType: 'tags' },
      });

      const items = findBreadcrumb().props('items');

      expect(items).toStrictEqual([
        {
          text: 'gitlab',
          to: '/v1.0?ref_type=tags',
        },
        {
          text: 'README.md',
          to: '/v1.0/README.md?ref_type=tags',
        },
      ]);
    });
  });

  describe('nested directory path', () => {
    beforeEach(() => {
      createComponent({ path: 'app/assets/javascripts' });
    });

    it('creates breadcrumb items for each path segment', () => {
      const items = findBreadcrumb().props('items');

      expect(items).toStrictEqual([
        {
          text: 'gitlab',
          to: '/main?ref_type=heads',
        },
        {
          text: 'app',
          to: '/main/app?ref_type=heads',
        },
        {
          text: 'assets',
          to: '/main/app/assets?ref_type=heads',
        },
        {
          text: 'javascripts',
          to: '/main/app/assets/javascripts?ref_type=heads',
        },
      ]);
    });
  });

  describe('file paths with special characters', () => {
    it('properly escapes file names with spaces and special characters', () => {
      createComponent({ path: 'src/My Component #1.vue' });

      const items = findBreadcrumb().props('items');

      expect(items).toStrictEqual([
        {
          text: 'gitlab',
          to: '/main?ref_type=heads',
        },
        {
          text: 'src',
          to: '/main/src?ref_type=heads',
        },
        {
          text: 'My Component #1.vue',
          to: '/main/src/My%20Component%20%231.vue?ref_type=heads',
        },
      ]);
    });
  });
});

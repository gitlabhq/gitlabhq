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
    path: 'README.md',
  };

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(CommitListBreadcrumb, {
      provide: {
        ...defaultProvide,
        ...provide,
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
      items: [
        {
          text: 'gitlab',
          to: '/gitlab-org/gitlab/-/commits/main?ref_type=heads',
        },
        {
          text: 'README.md',
          to: '/gitlab-org/gitlab/-/commits/main/README.md?ref_type=heads',
        },
      ],
    });
  });

  describe('project root breadcrumb (no path)', () => {
    it('shows only project name for root path', () => {
      createComponent({
        provide: {
          path: '',
        },
      });

      const items = findBreadcrumb().props('items');

      expect(items).toStrictEqual([
        {
          text: 'gitlab',
          to: '/gitlab-org/gitlab/-/commits/main?ref_type=heads',
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
          to: '/gitlab-org/gitlab/-/commits/v1.0?ref_type=tags', // Use v1.0 and tags
        },
        {
          text: 'README.md',
          to: '/gitlab-org/gitlab/-/commits/v1.0/README.md?ref_type=tags', // Use v1.0 and tags
        },
      ]);
    });
  });

  describe('nested directory path', () => {
    beforeEach(() => {
      createComponent({
        provide: {
          path: 'app/assets/javascripts',
        },
      });
    });

    it('creates breadcrumb items for each path segment', () => {
      const items = findBreadcrumb().props('items');

      expect(items).toStrictEqual([
        {
          text: 'gitlab',
          to: '/gitlab-org/gitlab/-/commits/main?ref_type=heads',
        },
        {
          text: 'app',
          to: '/gitlab-org/gitlab/-/commits/main/app?ref_type=heads',
        },
        {
          text: 'assets',
          to: '/gitlab-org/gitlab/-/commits/main/app/assets?ref_type=heads',
        },
        {
          text: 'javascripts',
          to: '/gitlab-org/gitlab/-/commits/main/app/assets/javascripts?ref_type=heads',
        },
      ]);
    });
  });

  describe('file paths with special characters', () => {
    it('properly escapes file names with spaces and special characters', () => {
      createComponent({
        provide: {
          path: 'src/My Component #1.vue',
        },
      });

      const items = findBreadcrumb().props('items');

      expect(items).toStrictEqual([
        {
          text: 'gitlab',
          to: '/gitlab-org/gitlab/-/commits/main?ref_type=heads',
        },
        {
          text: 'src',
          to: '/gitlab-org/gitlab/-/commits/main/src?ref_type=heads',
        },
        {
          text: 'My Component #1.vue',
          to: '/gitlab-org/gitlab/-/commits/main/src/My%20Component%20%231.vue?ref_type=heads',
        },
      ]);
    });
  });
});

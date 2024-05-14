import { GlBadge } from '@gitlab/ui';
import projects from 'test_fixtures/api/users/projects/get.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import ProjectListItemInactiveBadge from '~/vue_shared/components/projects_list/project_list_item_inactive_badge.vue';

describe('ProjectListItemInactiveBadgeCE', () => {
  let wrapper;

  const [project] = convertObjectPropsToCamelCase(projects, { deep: true });

  const defaultProps = {
    project,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(ProjectListItemInactiveBadge, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findGlBadge = () => wrapper.findComponent(GlBadge);

  describe('project is marked as archived', () => {
    beforeEach(() => {
      createComponent({
        props: {
          project: {
            ...project,
            archived: true,
          },
        },
      });
    });

    it('renders badge correctly', () => {
      expect(findGlBadge().props('variant')).toBe('info');
      expect(findGlBadge().text()).toBe('Archived');
    });
  });

  describe('project is not marked as archived', () => {
    beforeEach(() => {
      createComponent({
        props: {
          project: {
            ...project,
            archived: false,
          },
        },
      });
    });

    it('does not render badge', () => {
      expect(findGlBadge().exists()).toBe(false);
    });
  });
});

import projects from 'test_fixtures/api/users/projects/get.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import ProjectListItemActions from '~/vue_shared/components/projects_list/project_list_item_actions.vue';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';

describe('ProjectListItemActionsCE', () => {
  let wrapper;

  const [project] = convertObjectPropsToCamelCase(projects, { deep: true });

  const editPath = '/foo/bar/edit';
  const projectWithActions = {
    ...project,
    availableActions: [ACTION_EDIT, ACTION_DELETE],
    editPath,
  };

  const defaultProps = {
    project: projectWithActions,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(ProjectListItemActions, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findListActions = () => wrapper.findComponent(ListActions);

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('displays actions dropdown', () => {
      expect(findListActions().props()).toMatchObject({
        actions: {
          [ACTION_EDIT]: {
            href: editPath,
          },
          [ACTION_DELETE]: {
            action: expect.any(Function),
          },
        },
        availableActions: [ACTION_EDIT, ACTION_DELETE],
      });
    });
  });

  describe('when delete action is fired', () => {
    beforeEach(() => {
      findListActions().props('actions')[ACTION_DELETE].action();
    });

    it('emits delete event', () => {
      expect(wrapper.emitted('delete')).toEqual([[]]);
    });
  });
});

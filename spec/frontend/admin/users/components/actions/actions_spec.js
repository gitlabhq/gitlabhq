import { GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Actions from '~/admin/users/components/actions';
import eventHub, {
  EVENT_OPEN_DELETE_USER_MODAL,
} from '~/admin/users/components/modals/delete_user_modal_event_hub';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { OBSTACLE_TYPES } from '~/vue_shared/components/user_deletion_obstacles/constants';
import { CONFIRMATION_ACTIONS, DELETE_ACTIONS } from '../../constants';
import { paths } from '../../mock_data';

describe('Action components', () => {
  let wrapper;

  const findDropdownItem = () => wrapper.find(GlDropdownItem);

  const initComponent = ({ component, props } = {}) => {
    wrapper = shallowMount(component, {
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('CONFIRMATION_ACTIONS', () => {
    it.each(CONFIRMATION_ACTIONS)('renders a dropdown item for "%s"', (action) => {
      initComponent({
        component: Actions[capitalizeFirstCharacter(action)],
        props: {
          username: 'John Doe',
          path: '/test',
        },
      });

      expect(findDropdownItem().exists()).toBe(true);
    });
  });

  describe('DELETE_ACTION_COMPONENTS', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation();
    });

    const userDeletionObstacles = [
      { name: 'schedule1', type: OBSTACLE_TYPES.oncallSchedules },
      { name: 'policy1', type: OBSTACLE_TYPES.escalationPolicies },
    ];

    it.each(DELETE_ACTIONS)(
      'renders a dropdown item that opens the delete user modal when clicked for "%s"',
      async (action) => {
        initComponent({
          component: Actions[capitalizeFirstCharacter(action)],
          props: {
            username: 'John Doe',
            paths,
            userDeletionObstacles,
          },
        });

        await findDropdownItem().vm.$emit('click');

        expect(eventHub.$emit).toHaveBeenCalledWith(
          EVENT_OPEN_DELETE_USER_MODAL,
          expect.objectContaining({
            username: 'John Doe',
            blockPath: paths.block,
            deletePath: paths[action],
            userDeletionObstacles,
          }),
        );
      },
    );
  });
});

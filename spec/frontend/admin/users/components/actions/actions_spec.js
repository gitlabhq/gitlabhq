import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Actions from '~/admin/users/components/actions';
import Delete from '~/admin/users/components/actions/delete.vue';
import eventHub, {
  EVENT_OPEN_DELETE_USER_MODAL,
} from '~/admin/users/components/modals/delete_user_modal_event_hub';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { CONFIRMATION_ACTIONS } from '../../constants';
import { paths, userDeletionObstacles } from '../../mock_data';

describe('Action components', () => {
  let wrapper;

  const findDisclosureDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  const initComponent = ({ component, props } = {}) => {
    wrapper = shallowMount(component, {
      propsData: {
        ...props,
      },
    });
  };

  describe('CONFIRMATION_ACTIONS', () => {
    it.each(CONFIRMATION_ACTIONS)('renders a dropdown item for "%s"', (action) => {
      initComponent({
        component: Actions[capitalizeFirstCharacter(action)],
        props: {
          username: 'John Doe',
          path: '/test',
        },
      });

      expect(findDisclosureDropdownItem().exists()).toBe(true);
    });
  });

  describe('DELETE', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation();
    });

    it('renders a dropdown item that opens the delete user modal when Delete is clicked', async () => {
      initComponent({
        component: Delete,
        props: {
          username: 'John Doe',
          userId: 1,
          paths,
          userDeletionObstacles,
        },
      });

      await findDisclosureDropdownItem().vm.$emit('action');

      expect(eventHub.$emit).toHaveBeenCalledWith(
        EVENT_OPEN_DELETE_USER_MODAL,
        expect.objectContaining({
          username: 'John Doe',
          blockPath: paths.block,
          deletePath: paths.delete,
          userDeletionObstacles,
        }),
      );
    });
  });
});

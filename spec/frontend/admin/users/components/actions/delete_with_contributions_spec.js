import { GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import DeleteWithContributions from '~/admin/users/components/actions/delete_with_contributions.vue';
import eventHub, {
  EVENT_OPEN_DELETE_USER_MODAL,
} from '~/admin/users/components/modals/delete_user_modal_event_hub';
import { associationsCount } from '~/api/user_api';
import {
  paths,
  associationsCount as associationsCountData,
  userDeletionObstacles,
} from '../../mock_data';

jest.mock('~/admin/users/components/modals/delete_user_modal_event_hub', () => ({
  ...jest.requireActual('~/admin/users/components/modals/delete_user_modal_event_hub'),
  __esModule: true,
  default: {
    $emit: jest.fn(),
  },
}));

jest.mock('~/api/user_api', () => ({
  associationsCount: jest.fn(),
}));

describe('DeleteWithContributions', () => {
  let wrapper;

  const defaultPropsData = {
    username: 'John Doe',
    userId: 1,
    paths,
    userDeletionObstacles,
  };

  const createComponent = () => {
    wrapper = mount(DeleteWithContributions, { propsData: defaultPropsData });
  };

  describe('when action is clicked', () => {
    describe('when API request is loading', () => {
      beforeEach(() => {
        associationsCount.mockReturnValueOnce(new Promise(() => {}));

        createComponent();
      });

      it('displays loading icon and disables button', async () => {
        await wrapper.find('button').trigger('click');

        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
        expect(wrapper.attributes()).toMatchObject({
          disabled: 'disabled',
          'aria-busy': 'true',
        });
      });
    });

    describe('when API request is successful', () => {
      beforeEach(() => {
        associationsCount.mockResolvedValueOnce({
          data: associationsCountData,
        });

        createComponent();
      });

      it('emits event with association counts', async () => {
        await wrapper.find('button').trigger('click');
        await waitForPromises();

        expect(associationsCount).toHaveBeenCalledWith(defaultPropsData.userId);
        expect(eventHub.$emit).toHaveBeenCalledWith(
          EVENT_OPEN_DELETE_USER_MODAL,
          expect.objectContaining({
            associationsCount: associationsCountData,
            username: defaultPropsData.username,
            blockPath: paths.block,
            deletePath: paths.deleteWithContributions,
            userDeletionObstacles,
          }),
        );
      });
    });

    describe('when API request is not successful', () => {
      beforeEach(() => {
        associationsCount.mockRejectedValueOnce();

        createComponent();
      });

      it('emits event with error', async () => {
        await wrapper.find('button').trigger('click');
        await waitForPromises();

        expect(eventHub.$emit).toHaveBeenCalledWith(
          EVENT_OPEN_DELETE_USER_MODAL,
          expect.objectContaining({
            associationsCount: new Error(),
          }),
        );
      });
    });
  });
});

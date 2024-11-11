import { GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import DeleteWithContributions from '~/admin/users/components/actions/delete_with_contributions.vue';
import eventHub, {
  EVENT_OPEN_DELETE_USER_MODAL,
} from '~/admin/users/components/modals/delete_user_modal_event_hub';
import { associationsCount } from '~/api/user_api';
import { getSoloOwnedOrganizations } from '~/admin/users/utils';
import { SOLO_OWNED_ORGANIZATIONS_EMPTY } from '~/admin/users/constants';
import {
  paths,
  associationsCount as associationsCountData,
  userDeletionObstacles,
  oneSoloOwnedOrganization,
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

jest.mock('~/admin/users/utils', () => ({
  getSoloOwnedOrganizations: jest.fn(),
}));

Vue.use(VueApollo);

describe('DeleteWithContributions', () => {
  let wrapper;

  const defaultPropsData = {
    username: 'John Doe',
    userId: 1,
    paths,
    userDeletionObstacles,
  };

  const createComponent = () => {
    wrapper = mount(DeleteWithContributions, {
      propsData: defaultPropsData,
      apolloProvider: createMockApollo([]),
    });
  };

  describe('when action is clicked', () => {
    describe('when API request is loading', () => {
      beforeEach(() => {
        getSoloOwnedOrganizations.mockReturnValueOnce(new Promise(() => {}));

        createComponent();
      });

      it('displays loading icon and disables button', async () => {
        await wrapper.find('button').trigger('click');

        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
        // Vue 2 specs return 'disabled' while Vue 3 tests return true
        // eslint-disable-next-line jest/no-restricted-matchers
        expect(wrapper.attributes('disabled')).toBeTruthy();
        expect(wrapper.attributes('aria-busy')).toBe('true');
      });
    });

    describe('when solo organizations API call returns results', () => {
      beforeEach(() => {
        getSoloOwnedOrganizations.mockResolvedValueOnce(oneSoloOwnedOrganization);

        createComponent();
      });

      it('emits event with organizations and no association counts', async () => {
        await wrapper.find('button').trigger('click');
        await waitForPromises();

        expect(associationsCount).not.toHaveBeenCalledWith();
        expect(eventHub.$emit).toHaveBeenCalledWith(
          EVENT_OPEN_DELETE_USER_MODAL,
          expect.objectContaining({
            associationsCount: undefined,
            organizations: oneSoloOwnedOrganization,
            username: defaultPropsData.username,
            blockPath: paths.block,
            deletePath: paths.deleteWithContributions,
            userDeletionObstacles,
          }),
        );
      });
    });

    describe('when solo owned organizations API call returns no results', () => {
      beforeEach(() => {
        getSoloOwnedOrganizations.mockResolvedValueOnce(SOLO_OWNED_ORGANIZATIONS_EMPTY);
        associationsCount.mockResolvedValueOnce({
          data: associationsCountData,
        });

        createComponent();
      });

      it('makes association count API call and emits event with association counts', async () => {
        await wrapper.find('button').trigger('click');
        await waitForPromises();

        expect(associationsCount).toHaveBeenCalledWith(defaultPropsData.userId);
        expect(eventHub.$emit).toHaveBeenCalledWith(
          EVENT_OPEN_DELETE_USER_MODAL,
          expect.objectContaining({
            associationsCount: associationsCountData,
            organizations: SOLO_OWNED_ORGANIZATIONS_EMPTY,
            username: defaultPropsData.username,
            blockPath: paths.block,
            deletePath: paths.deleteWithContributions,
            userDeletionObstacles,
          }),
        );
      });
    });

    describe('when solo owned organizations API call is not successful', () => {
      beforeEach(() => {
        getSoloOwnedOrganizations.mockRejectedValueOnce(new Error());

        createComponent();
      });

      it('emits event with empty organizations', async () => {
        await wrapper.find('button').trigger('click');
        await waitForPromises();

        expect(associationsCount).not.toHaveBeenCalledWith();
        expect(eventHub.$emit).toHaveBeenCalledWith(
          EVENT_OPEN_DELETE_USER_MODAL,
          expect.objectContaining({
            associationsCount: undefined,
            organizations: SOLO_OWNED_ORGANIZATIONS_EMPTY,
            username: defaultPropsData.username,
            blockPath: paths.block,
            deletePath: paths.deleteWithContributions,
            userDeletionObstacles,
          }),
        );
      });
    });

    describe('when association count API call is not successful', () => {
      beforeEach(() => {
        getSoloOwnedOrganizations.mockResolvedValueOnce(SOLO_OWNED_ORGANIZATIONS_EMPTY);
        associationsCount.mockRejectedValueOnce(new Error());

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

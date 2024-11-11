import { GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Delete from '~/admin/users/components/actions/delete.vue';
import eventHub, {
  EVENT_OPEN_DELETE_USER_MODAL,
} from '~/admin/users/components/modals/delete_user_modal_event_hub';
import { getSoloOwnedOrganizations } from '~/admin/users/utils';
import { SOLO_OWNED_ORGANIZATIONS_EMPTY } from '~/admin/users/constants';
import { paths, oneSoloOwnedOrganization } from '../../mock_data';

jest.mock('~/admin/users/components/modals/delete_user_modal_event_hub', () => ({
  ...jest.requireActual('~/admin/users/components/modals/delete_user_modal_event_hub'),
  __esModule: true,
  default: {
    $emit: jest.fn(),
  },
}));

jest.mock('~/admin/users/utils', () => ({
  getSoloOwnedOrganizations: jest.fn(),
}));

Vue.use(VueApollo);

describe('Delete', () => {
  let wrapper;

  const defaultPropsData = {
    username: 'John Doe',
    userId: 1,
    paths,
  };

  const createComponent = () => {
    wrapper = mount(Delete, { propsData: defaultPropsData, apolloProvider: createMockApollo([]) });
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

    describe('when API request is successful', () => {
      beforeEach(() => {
        getSoloOwnedOrganizations.mockResolvedValueOnce(oneSoloOwnedOrganization);

        createComponent();
      });

      it('emits event with association counts and organizations', async () => {
        await wrapper.find('button').trigger('click');
        await waitForPromises();

        expect(eventHub.$emit).toHaveBeenCalledWith(
          EVENT_OPEN_DELETE_USER_MODAL,
          expect.objectContaining({
            organizations: oneSoloOwnedOrganization,
            username: defaultPropsData.username,
            blockPath: paths.block,
            deletePath: paths.delete,
          }),
        );
      });
    });

    describe('when API request is not successful', () => {
      beforeEach(() => {
        getSoloOwnedOrganizations.mockRejectedValueOnce();

        createComponent();
      });

      it('emits event with empty organizations', async () => {
        await wrapper.find('button').trigger('click');
        await waitForPromises();

        expect(eventHub.$emit).toHaveBeenCalledWith(
          EVENT_OPEN_DELETE_USER_MODAL,
          expect.objectContaining({
            organizations: SOLO_OWNED_ORGANIZATIONS_EMPTY,
            username: defaultPropsData.username,
            blockPath: paths.block,
            deletePath: paths.delete,
          }),
        );
      });
    });
  });
});

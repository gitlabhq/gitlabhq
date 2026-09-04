import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import RemoveFromOrganization from '~/admin/users/components/actions/remove_from_organization.vue';
import eventHub, {
  EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL,
} from '~/admin/users/components/modals/remove_from_organization_modal_event_hub';

jest.mock('~/admin/users/components/modals/remove_from_organization_modal_event_hub', () => ({
  ...jest.requireActual('~/admin/users/components/modals/remove_from_organization_modal_event_hub'),
  __esModule: true,
  default: {
    $emit: jest.fn(),
  },
}));

describe('RemoveFromOrganization', () => {
  let wrapper;

  const defaultPropsData = {
    username: 'John Doe',
    organizationUserGid: 'gid://gitlab/Organizations::OrganizationUser/1',
  };

  const createComponent = () => {
    wrapper = mount(RemoveFromOrganization, {
      propsData: defaultPropsData,
      slots: { default: 'Remove from organization' },
    });
  };

  it('renders a danger variant dropdown item', () => {
    createComponent();

    expect(wrapper.findComponent(GlDisclosureDropdownItem).props('variant')).toBe('danger');
  });

  describe('when action is clicked', () => {
    it('emits the open modal event with username and organization user GID', async () => {
      createComponent();

      await wrapper.find('button').trigger('click');

      expect(eventHub.$emit).toHaveBeenCalledWith(EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL, {
        username: defaultPropsData.username,
        organizationUserGid: defaultPropsData.organizationUserGid,
      });
    });
  });
});

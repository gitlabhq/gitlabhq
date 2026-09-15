import { GlDisclosureDropdown, GlEmptyState } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/organizations/show/components/app.vue';
import LeaveOrganizationModal from '~/organizations/show/components/leave_organization_modal.vue';

describe('OrganizationShowApp', () => {
  let wrapper;

  const defaultPropsData = {
    organization: {
      name: 'GitLab',
      path: 'gitlab',
    },
    canAdminOrganization: true,
  };

  const createComponent = ({ propsData } = {}) => {
    wrapper = mountExtended(App, { propsData: { ...defaultPropsData, ...propsData } });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findActionsDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findLeaveAction = () => wrapper.findByTestId('leave-organization-action');
  const findLeaveModal = () => wrapper.findComponent(LeaveOrganizationModal);

  const itRendersEmptyStateWithCorrectDescription = (description) => {
    it('renders empty state with correct description', () => {
      expect(findEmptyState().text()).toContain(description);
    });
  };

  const itRendersLearnMoreLink = () => {
    it('renders learn more link', () => {
      expect(wrapper.findByRole('link', { name: 'Learn more' }).attributes('href')).toBe(
        '/help/user/organization/_index.md',
      );
    });
  };

  describe('when user can admin organization', () => {
    beforeEach(() => {
      createComponent();
    });

    itRendersEmptyStateWithCorrectDescription(
      `${defaultPropsData.organization.name} is your organization's home. Manage settings from the sidebar. Learn more.`,
    );

    itRendersLearnMoreLink();
  });

  describe('when user cannot admin organization', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          canAdminOrganization: false,
        },
      });
    });

    itRendersEmptyStateWithCorrectDescription(
      `${defaultPropsData.organization.name} is your organization's home. Learn more.`,
    );

    itRendersLearnMoreLink();
  });

  describe('actions dropdown', () => {
    describe('when user can leave organization', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            canLeaveOrganization: true,
            organizationUserGid: 'gid://gitlab/Organizations::OrganizationUser/1',
          },
        });
      });

      it('renders actions dropdown', () => {
        expect(findActionsDropdown().exists()).toBe(true);
      });

      it('renders leave organization action', () => {
        expect(findLeaveAction().text()).toBe('Leave organization');
      });

      it('renders leave organization modal', () => {
        expect(findLeaveModal().props()).toMatchObject({
          organization: defaultPropsData.organization,
          organizationUserGid: 'gid://gitlab/Organizations::OrganizationUser/1',
        });
      });

      it('shows the modal when the leave action is clicked', async () => {
        expect(findLeaveModal().props('visible')).toBe(false);

        await findLeaveAction().trigger('click');

        expect(findLeaveModal().props('visible')).toBe(true);
      });
    });

    describe('when user cannot leave organization', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            canLeaveOrganization: false,
            organizationUserGid: 'gid://gitlab/Organizations::OrganizationUser/1',
          },
        });
      });

      it('does not render actions dropdown', () => {
        expect(findActionsDropdown().exists()).toBe(false);
      });

      it('does not render leave organization modal', () => {
        expect(findLeaveModal().exists()).toBe(false);
      });
    });

    describe('when organizationUserGid is missing', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            canLeaveOrganization: true,
            organizationUserGid: null,
          },
        });
      });

      it('does not render actions dropdown', () => {
        expect(findActionsDropdown().exists()).toBe(false);
      });
    });
  });
});

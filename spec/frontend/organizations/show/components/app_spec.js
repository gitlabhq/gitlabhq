import { GlEmptyState } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/organizations/show/components/app.vue';

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
});

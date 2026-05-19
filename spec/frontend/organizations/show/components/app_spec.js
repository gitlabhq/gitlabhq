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
    canReadArtifactRegistry: true,
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
  const itRendersLinkToArtifactRegistry = () => {
    it('renders link to artifact registry', () => {
      expect(
        wrapper.findByRole('link', { name: 'Go to Artifact Registry' }).attributes('href'),
      ).toBe('/o/gitlab/-/artifact_registry');
    });
  };
  const itDoesNotRenderLinkToArtifactRegistry = () => {
    it('does not render link to artifact registry', () => {
      expect(wrapper.findByRole('link', { name: 'Go to Artifact Registry' }).exists()).toBe(false);
    });
  };
  const itRendersLearnMoreLink = () => {
    it('renders learn more link', () => {
      expect(wrapper.findByRole('link', { name: 'Learn more' }).attributes('href')).toBe(
        '/help/user/organization/_index.md',
      );
    });
  };

  describe('when user can read artifact registry and admin organization', () => {
    beforeEach(() => {
      createComponent();
    });

    itRendersEmptyStateWithCorrectDescription(
      `${defaultPropsData.organization.name} is your organization's home. Manage Artifact Registry and settings from the sidebar. Learn more.`,
    );

    itRendersLearnMoreLink();

    itRendersLinkToArtifactRegistry();
  });

  describe('when user can read artifact registry', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          canAdminOrganization: false,
        },
      });
    });

    itRendersEmptyStateWithCorrectDescription(
      `${defaultPropsData.organization.name} is your organization's home. Manage Artifact Registry from the sidebar. Learn more.`,
    );

    itRendersLearnMoreLink();

    itRendersLinkToArtifactRegistry();
  });

  describe('when user can admin organization', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          canReadArtifactRegistry: false,
        },
      });
    });

    itRendersEmptyStateWithCorrectDescription(
      `${defaultPropsData.organization.name} is your organization's home. Manage settings from the sidebar. Learn more.`,
    );

    itRendersLearnMoreLink();

    itDoesNotRenderLinkToArtifactRegistry();
  });

  describe('when user cannot read artifact registry or admin organization', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          canReadArtifactRegistry: false,
          canAdminOrganization: false,
        },
      });
    });

    itRendersEmptyStateWithCorrectDescription(
      `${defaultPropsData.organization.name} is your organization's home. Learn more.`,
    );

    itRendersLearnMoreLink();

    itDoesNotRenderLinkToArtifactRegistry();
  });
});

import { GlAvatarLabeled, GlCard } from '@gitlab/ui';
import gitlabLogoUrl from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg?url';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OrganizationCard from '~/organizations/index/components/reconciliation/organization_card.vue';
import { mockDefaultOrganization } from 'jest/organizations/shared/mock_data';
import { mockOrganizations } from './mock_data';

describe('OrganizationCard', () => {
  let wrapper;

  const [nonDefaultOrganization] = mockOrganizations;

  const createComponent = ({ props = {}, slots = {} } = {}) => {
    wrapper = shallowMountExtended(OrganizationCard, {
      propsData: {
        organization: nonDefaultOrganization,
        ...props,
      },
      slots,
      stubs: {
        GlCard,
      },
    });
  };

  const findCard = () => wrapper.findComponent(GlCard);
  const findAvatar = () => wrapper.findComponent(GlAvatarLabeled);

  describe('avatar', () => {
    it('renders organization name and avatar', () => {
      createComponent();

      expect(findAvatar().props()).toMatchObject({
        label: nonDefaultOrganization.name,
        entityName: nonDefaultOrganization.name,
        src: nonDefaultOrganization.avatarUrl,
      });
    });

    describe('when organization is the default organization', () => {
      beforeEach(() => {
        createComponent({ props: { organization: mockDefaultOrganization } });
      });

      it('renders "GitLab" as the label', () => {
        expect(findAvatar().props('label')).toBe('GitLab');
        expect(findAvatar().props('entityName')).toBe('GitLab');
      });

      it('renders GitLab logo as avatar src', () => {
        expect(findAvatar().props('src')).toBe(gitlabLogoUrl);
      });
    });
  });

  describe('card body', () => {
    it('hides card body when no default slot content is provided', () => {
      createComponent();

      expect(findCard().props('bodyClass')).toContain('gl-hidden');
    });

    it('shows card body when default slot content is provided', () => {
      createComponent({ slots: { default: '<div>slot content</div>' } });

      expect(findCard().props('bodyClass')).not.toContain('gl-hidden');
    });
  });

  describe('card header', () => {
    it('adds bottom padding class when no default slot content is provided', () => {
      createComponent();

      expect(findCard().props('headerClass')).toEqual({ 'gl-pb-2': true });
    });

    it('does not add bottom padding class when default slot content is provided', () => {
      createComponent({ slots: { default: '<div>slot content</div>' } });

      expect(findCard().props('headerClass')).toEqual({ 'gl-pb-2': false });
    });
  });

  describe('default slot', () => {
    it('renders slot content', () => {
      createComponent({ slots: { default: '<div data-testid="slot-content">test</div>' } });

      expect(wrapper.findByTestId('slot-content').exists()).toBe(true);
    });
  });
});

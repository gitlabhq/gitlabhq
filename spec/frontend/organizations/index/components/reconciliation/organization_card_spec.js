import { GlAvatarLabeled, GlCard } from '@gitlab/ui';
import gitlabLogoUrl from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg?url';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
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
        GlAvatarLabeled: stubComponent(GlAvatarLabeled, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const buildOrganization = ({ visibility, groupVisibilities = [] }) => ({
    ...nonDefaultOrganization,
    visibility,
    groups: {
      ...nonDefaultOrganization.groups,
      nodes: groupVisibilities.map((groupVisibility, index) => ({
        id: `gid://gitlab/Group/${index + 1}`,
        fullName: `group-${index + 1}`,
        groupMembersCount: 0,
        projectsCount: 0,
        descendantGroupsCount: 0,
        visibility: groupVisibility,
        __typename: 'Group',
      })),
    },
  });

  const findCard = () => wrapper.findComponent(GlCard);
  const findAvatar = () => wrapper.findComponent(GlAvatarLabeled);
  const findVisibilityIcon = () => wrapper.findByTestId('organization-visibility');

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

  describe('organization visibility', () => {
    describe('when organization is the default organization', () => {
      it('does not render visibility icon', () => {
        createComponent({ props: { organization: mockDefaultOrganization } });

        expect(findVisibilityIcon().exists()).toBe(false);
      });
    });

    describe('when organization is not the default organization', () => {
      it.each`
        scenario                                 | orgVisibility | groupVisibilities        | expectedIcon | expectedTooltip
        ${'no groups, private org'}              | ${'private'}  | ${[]}                    | ${'lock'}    | ${'Private - The organization can only be viewed by members.'}
        ${'no groups, public org'}               | ${'public'}   | ${[]}                    | ${'earth'}   | ${'Public - The organization can be accessed without any authentication.'}
        ${'org broader than groups'}             | ${'public'}   | ${['private']}           | ${'earth'}   | ${'Public - The organization can be accessed without any authentication.'}
        ${'org equal to groups'}                 | ${'private'}  | ${['private']}           | ${'lock'}    | ${'Private - The organization can only be viewed by members.'}
        ${'group broader than org'}              | ${'private'}  | ${['public']}            | ${'earth'}   | ${'Public - The organization can be accessed without any authentication.'}
        ${'broadest of multiple groups is used'} | ${'private'}  | ${['private', 'public']} | ${'earth'}   | ${'Public - The organization can be accessed without any authentication.'}
      `(
        'renders correct visibility icon and tooltip when $scenario',
        ({ orgVisibility, groupVisibilities, expectedIcon, expectedTooltip }) => {
          createComponent({
            props: {
              organization: buildOrganization({
                visibility: orgVisibility,
                groupVisibilities,
              }),
            },
          });

          const icon = findVisibilityIcon();

          expect(icon.props('name')).toBe(expectedIcon);
          expect(getBinding(icon.element, 'gl-tooltip').value).toBe(expectedTooltip);
        },
      );
    });
  });
});

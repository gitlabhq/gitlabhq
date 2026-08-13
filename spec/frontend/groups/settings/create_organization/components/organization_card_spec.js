import { GlAvatarLabeled, GlCard } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import OrganizationCard from '~/groups/settings/create_organization/components/organization_card.vue';
import { mockDefaultOrganization } from 'jest/organizations/shared/mock_data';
import { mockOrganizations } from './mock_data';

describe('OrganizationCard', () => {
  let wrapper;

  const [nonDefaultOrganization] = mockOrganizations;

  const createComponent = ({ props = {}, scopedSlots = {} } = {}) => {
    wrapper = shallowMountExtended(OrganizationCard, {
      propsData: {
        organization: nonDefaultOrganization,
        ...props,
      },
      scopedSlots,
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

  const findCard = () => wrapper.findComponent(GlCard);
  const findAvatar = () => wrapper.findComponent(GlAvatarLabeled);
  const findVisibilityIcon = () => wrapper.findComponentByTestId('organization-visibility');

  describe('when organization is not the default organization', () => {
    it('renders organization name and avatar', () => {
      createComponent();

      expect(findAvatar().props()).toMatchObject({
        label: nonDefaultOrganization.name,
        entityName: nonDefaultOrganization.name,
        src: nonDefaultOrganization.avatarUrl,
      });
    });

    it.each`
      visibility   | expectedIcon | expectedTooltip
      ${'public'}  | ${'earth'}   | ${'Public - The organization can be accessed without any authentication.'}
      ${'private'} | ${'lock'}    | ${'Private - The organization can only be viewed by members.'}
    `(
      'renders the $visibility visibility icon and tooltip based on the organization visibility',
      ({ visibility, expectedIcon, expectedTooltip }) => {
        createComponent({
          props: {
            organization: { ...nonDefaultOrganization, visibility },
          },
        });

        const icon = findVisibilityIcon();

        expect(icon.props('name')).toBe(expectedIcon);
        expect(getBinding(icon.element, 'gl-tooltip').value).toBe(expectedTooltip);
      },
    );

    it('passes `isDefaultOrganization` as `false` to the default slot', () => {
      createComponent({
        scopedSlots: {
          default: '<div data-testid="slot-content">{{ props.isDefaultOrganization }}</div>',
        },
      });

      expect(wrapper.findByTestId('slot-content').text()).toBe('false');
    });
  });

  describe('when organization is the default organization', () => {
    beforeEach(() => {
      createComponent({ props: { organization: mockDefaultOrganization } });
    });

    it('renders the other top-level groups header instead of an avatar', () => {
      expect(findAvatar().exists()).toBe(false);
      expect(findCard().text()).toContain('Other top-level groups');
    });

    it('does not render visibility icon', () => {
      expect(findVisibilityIcon().exists()).toBe(false);
    });

    it('renders the card with a border and transparent background', () => {
      expect(findCard().classes()).toEqual(
        expect.arrayContaining(['gl-border', 'gl-h-full', 'gl-bg-transparent']),
      );
    });

    it('passes `isDefaultOrganization` as `true` to the default slot', () => {
      createComponent({
        props: { organization: mockDefaultOrganization },
        scopedSlots: {
          default: '<div data-testid="slot-content">{{ props.isDefaultOrganization }}</div>',
        },
      });

      expect(wrapper.findByTestId('slot-content').text()).toBe('true');
    });
  });

  describe('card body', () => {
    it('hides card body when no default slot content is provided', () => {
      createComponent();

      expect(findCard().props('bodyClass')).toContain('gl-hidden');
    });

    it('shows card body when default slot content is provided', () => {
      createComponent({ scopedSlots: { default: '<div>slot content</div>' } });

      expect(findCard().props('bodyClass')).not.toContain('gl-hidden');
    });
  });

  describe('card header', () => {
    it('adds bottom padding class when no default slot content is provided', () => {
      createComponent();

      expect(findCard().props('headerClass')).toEqual({ 'gl-pb-2': true });
    });

    it('does not add bottom padding class when default slot content is provided', () => {
      createComponent({ scopedSlots: { default: '<div>slot content</div>' } });

      expect(findCard().props('headerClass')).toEqual({ 'gl-pb-2': false });
    });
  });

  describe('default slot', () => {
    it('renders slot content', () => {
      createComponent({ scopedSlots: { default: '<div data-testid="slot-content">test</div>' } });

      expect(wrapper.findByTestId('slot-content').exists()).toBe(true);
    });
  });
});

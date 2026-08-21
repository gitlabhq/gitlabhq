import illustrationUrl from '@gitlab/svgs/dist/illustrations/empty-state/empty-organizations-add-md.svg?url';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Step1 from '~/groups/settings/create_organization/components/steps/step_1.vue';
import BaseStep from '~/groups/settings/create_organization/components/steps/base_step.vue';
import OrganizationCard from '~/groups/settings/create_organization/components/organization_card.vue';
import OrganizationGroupStats from '~/groups/settings/create_organization/components/organization_group_stats.vue';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { mockNewOrganization } from '../mock_data';

describe('ReconciliationStep1', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(Step1, {
      propsData: {
        organization: mockNewOrganization,
        ...props,
      },
      stubs: {
        BaseStep,
      },
    });
  };

  const findBaseStep = () => wrapper.findComponent(BaseStep);
  const findOrganizationCards = () => wrapper.findAllComponents(OrganizationCard);
  const findHelpPageLink = () => wrapper.findComponent(HelpPageLink);
  const findAllGroupStats = () => wrapper.findAllComponents(OrganizationGroupStats);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders BaseStep with title', () => {
      expect(findBaseStep().props('title')).toBe('Create your Organizations');
    });

    it('renders BaseStep with illustration', () => {
      expect(findBaseStep().props('illustration')).toBe(illustrationUrl);
    });

    it('renders description text', () => {
      expect(wrapper.text()).toContain(
        'Create an organization to manage your top-level groups. You can set up your organization structure in the next step.',
      );
    });

    it('renders help page link', () => {
      expect(findHelpPageLink().attributes('href')).toBe('user/organization/_index.md');
      expect(findHelpPageLink().text()).toBe('Learn how Organizations work');
    });

    it('renders a single organization card for the organization to be created', () => {
      expect(findOrganizationCards()).toHaveLength(1);
      expect(findOrganizationCards().at(0).props('organization')).toEqual(mockNewOrganization);
    });

    it('renders group stats for the organization group', () => {
      const [group] = mockNewOrganization.groups.nodes;

      expect(findAllGroupStats()).toHaveLength(1);
      expect(findAllGroupStats().at(0).props('group')).toEqual(group);
    });
  });

  describe('when organization has multiple groups', () => {
    it('renders group stats for the first group only', () => {
      const [group] = mockNewOrganization.groups.nodes;

      createComponent({
        props: {
          organization: {
            ...mockNewOrganization,
            groups: { nodes: [group, { ...group, id: 'gid://gitlab/Group/2' }] },
          },
        },
      });

      expect(findAllGroupStats()).toHaveLength(1);
      expect(findAllGroupStats().at(0).props('group')).toEqual(group);
    });
  });

  describe('when organization has no groups', () => {
    it('does not render group stats', () => {
      createComponent({
        props: {
          organization: { ...mockNewOrganization, groups: { nodes: [] } },
        },
      });

      expect(findAllGroupStats()).toHaveLength(0);
    });
  });
});

import { GlCard } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Step3 from '~/organizations/index/components/reconciliation/steps/step_3.vue';
import BaseStep from '~/organizations/index/components/reconciliation/steps/base_step.vue';
import OrganizationCard from '~/organizations/index/components/reconciliation/organization_card.vue';
import OrganizationGroupCard from '~/organizations/index/components/reconciliation/organization_group_card.vue';
import {
  mockOrganizations,
  organizationWithGroups,
  organizationsWithoutGroups,
} from '../mock_data';

describe('ReconciliationStep3', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(Step3, {
      propsData: {
        organizations: mockOrganizations,
        ...props,
      },
      stubs: {
        BaseStep,
        OrganizationCard,
        GlCard,
      },
    });
  };

  const findBaseStep = () => wrapper.findComponent(BaseStep);
  const findRetainedSection = () => wrapper.findByTestId('retained-organizations-section');
  const findDeletedSection = () => wrapper.findByTestId('deleted-organizations-section');
  const findAllGroupCards = () => wrapper.findAllComponents(OrganizationGroupCard);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders step title', () => {
      expect(findBaseStep().props('title')).toBe('Organization summary');
    });

    it('renders step description', () => {
      expect(
        wrapper
          .findByText("Here's your final structure. Activate when you're happy with it.")
          .exists(),
      ).toBe(true);
    });

    describe('retained organizations section', () => {
      it('renders section heading', () => {
        expect(wrapper.findByText('Your new structure').exists()).toBe(true);
      });

      it('renders an organization card for each organization with groups', () => {
        const retainedOrgs = mockOrganizations.filter((org) => org.groups.nodes.length > 0);

        expect(retainedOrgs).toHaveLength(1);
        expect(findRetainedSection().findAllComponents(OrganizationCard)).toHaveLength(1);
      });

      it('passes organization prop to organization card', () => {
        expect(findRetainedSection().findComponent(OrganizationCard).props('organization')).toEqual(
          organizationWithGroups,
        );
      });

      describe('group cards', () => {
        const groups = organizationWithGroups.groups.nodes;

        it('renders an organization group card for each group', () => {
          expect(findAllGroupCards()).toHaveLength(groups.length);
        });

        it('passes group prop to organization group card', () => {
          expect(findAllGroupCards().at(0).props('group')).toEqual(groups[0]);
        });
      });
    });

    describe('to be deleted organizations section', () => {
      it('renders section heading', () => {
        expect(wrapper.findByText('These Organizations will be deleted').exists()).toBe(true);
      });

      it('renders an organization card for each organization without groups', () => {
        const deletedCards = findDeletedSection().findAllComponents(OrganizationCard);

        expect(deletedCards).toHaveLength(organizationsWithoutGroups.length);
        deletedCards.wrappers.forEach((card, index) => {
          expect(card.props('organization')).toEqual(organizationsWithoutGroups[index]);
        });
      });
    });
  });

  describe('when all organizations have groups', () => {
    const allWithGroups = mockOrganizations.map((org) => ({
      ...org,
      groups: {
        ...org.groups,
        nodes: org.groups.nodes.length
          ? org.groups.nodes
          : [
              {
                id: 'fake',
                fullName: 'Fake',
                visibility: 'public',
                projectsCount: 0,
                groupMembersCount: 0,
                descendantGroupsCount: 0,
              },
            ],
      },
    }));

    beforeEach(() => {
      createComponent({ props: { organizations: allWithGroups } });
    });

    it('does render retained section', () => {
      expect(findRetainedSection().exists()).toBe(true);
    });

    it('does not render deleted section', () => {
      expect(findDeletedSection().exists()).toBe(false);
    });
  });

  describe('when no organizations have groups', () => {
    const allEmpty = mockOrganizations.map((org) => ({
      ...org,
      groups: { ...org.groups, nodes: [] },
    }));

    beforeEach(() => {
      createComponent({ props: { organizations: allEmpty } });
    });

    it('does not render retained section', () => {
      expect(findRetainedSection().exists()).toBe(false);
    });

    it('does render deleted section', () => {
      expect(findDeletedSection().exists()).toBe(true);
    });
  });
});

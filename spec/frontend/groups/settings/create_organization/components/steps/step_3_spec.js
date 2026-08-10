import { GlCard } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Step3 from '~/groups/settings/create_organization/components/steps/step_3.vue';
import BaseStep from '~/groups/settings/create_organization/components/steps/base_step.vue';
import OrganizationCard from '~/groups/settings/create_organization/components/organization_card.vue';
import OrganizationGroupCard from '~/groups/settings/create_organization/components/organization_group_card.vue';
import { mockOrganizations, mockNewOrganization } from '../mock_data';

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
        expect(findRetainedSection().findAllComponents(OrganizationCard)).toHaveLength(2);
      });

      it('passes organization prop to organization card', () => {
        expect(findRetainedSection().findComponent(OrganizationCard).props('organization')).toEqual(
          mockNewOrganization,
        );
      });

      describe('group cards', () => {
        it('renders an organization group card for each group', () => {
          expect(findAllGroupCards()).toHaveLength(2);
        });

        it('passes group prop to organization group card', () => {
          expect(findAllGroupCards().at(0).props('group')).toEqual(
            mockNewOrganization.groups.nodes[0],
          );
        });
      });
    });
  });
});

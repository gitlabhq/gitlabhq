import illustrationUrl from '@gitlab/svgs/dist/illustrations/empty-state/empty-organizations-add-md.svg?url';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Step1 from '~/organizations/index/components/reconciliation/steps/step_1.vue';
import BaseStep from '~/organizations/index/components/reconciliation/steps/base_step.vue';
import OrganizationCard from '~/organizations/index/components/reconciliation/organization_card.vue';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { mockOrganizations } from '../mock_data';

describe('ReconciliationStep1', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(Step1, {
      propsData: {
        organizations: mockOrganizations,
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

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders BaseStep with title', () => {
      expect(findBaseStep().props('title')).toBe('Activate your Organizations');
    });

    it('renders BaseStep with illustration', () => {
      expect(findBaseStep().props('illustration')).toBe(illustrationUrl);
    });

    it('renders description text', () => {
      expect(wrapper.text()).toContain(
        "We'll create one Organization per top-level group. You can reassign groups between them in the next step.",
      );
    });

    it('renders help page link', () => {
      expect(findHelpPageLink().attributes('href')).toBe('user/organization/_index.md');
      expect(findHelpPageLink().text()).toBe('Learn how Organizations work');
    });

    it('renders an organization card for each organization', () => {
      expect(findOrganizationCards()).toHaveLength(mockOrganizations.length);
    });

    it('passes organization prop to organization card', () => {
      expect(findOrganizationCards().at(0).props('organization')).toEqual(mockOrganizations[0]);
    });
  });
});

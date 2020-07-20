import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TerraformPlan from '~/vue_merge_request_widget/components/terraform/terraform_plan.vue';
import {
  invalidPlanWithName,
  invalidPlanWithoutName,
  validPlanWithName,
  validPlanWithoutName,
} from './mock_data';

describe('TerraformPlan', () => {
  let wrapper;

  const findIcon = () => wrapper.find('[data-testid="change-type-icon"]');
  const findLogButton = () => wrapper.find('[data-testid="terraform-report-link"]');

  const mountWrapper = propsData => {
    wrapper = shallowMount(TerraformPlan, { stubs: { GlLink, GlSprintf }, propsData });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('valid plan with job_name', () => {
    beforeEach(() => {
      mountWrapper({ plan: validPlanWithName });
    });

    it('displays a document icon', () => {
      expect(findIcon().attributes('name')).toBe('doc-changes');
    });

    it('diplays the header text with a name', () => {
      expect(wrapper.text()).toContain(
        `The Terraform report ${validPlanWithName.job_name} was generated in your pipelines.`,
      );
    });

    it('diplays the reported changes', () => {
      expect(wrapper.text()).toContain(
        `Reported Resource Changes: ${validPlanWithName.create} to add, ${validPlanWithName.update} to change, ${validPlanWithName.delete} to delete`,
      );
    });

    it('renders button when url is found', () => {
      expect(findLogButton().exists()).toBe(true);
      expect(findLogButton().text()).toEqual('View full log');
    });
  });

  describe('valid plan without job_name', () => {
    beforeEach(() => {
      mountWrapper({ plan: validPlanWithoutName });
    });

    it('diplays the header text without a name', () => {
      expect(wrapper.text()).toContain('A Terraform report was generated in your pipelines.');
    });
  });

  describe('invalid plan with job_name', () => {
    beforeEach(() => {
      mountWrapper({ plan: invalidPlanWithName });
    });

    it('displays a warning icon', () => {
      expect(findIcon().attributes('name')).toBe('warning');
    });

    it('diplays the header text with a name', () => {
      expect(wrapper.text()).toContain(
        `The Terraform report ${invalidPlanWithName.job_name} failed to generate.`,
      );
    });

    it('diplays generic error since report values are missing', () => {
      expect(wrapper.text()).toContain('Generating the report caused an error.');
    });
  });

  describe('invalid plan with out job_name', () => {
    beforeEach(() => {
      mountWrapper({ plan: invalidPlanWithoutName });
    });

    it('diplays the header text without a name', () => {
      expect(wrapper.text()).toContain('A Terraform report failed to generate.');
    });

    it('does not render button because url is missing', () => {
      expect(findLogButton().exists()).toBe(false);
    });
  });
});

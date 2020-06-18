import { invalidPlan, validPlan } from './mock_data';
import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TerraformPlan from '~/vue_merge_request_widget/components/terraform/terraform_plan.vue';

describe('TerraformPlan', () => {
  let wrapper;

  const findLogButton = () => wrapper.find('.js-terraform-report-link');

  const mountWrapper = propsData => {
    wrapper = shallowMount(TerraformPlan, { stubs: { GlLink, GlSprintf }, propsData });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('validPlan', () => {
    beforeEach(() => {
      mountWrapper({ plan: validPlan });
    });

    it('diplays the plan job_name', () => {
      expect(wrapper.text()).toContain(
        `The Terraform report ${validPlan.job_name} was generated in your pipelines.`,
      );
    });

    it('diplays the reported changes', () => {
      expect(wrapper.text()).toContain(
        `Reported Resource Changes: ${validPlan.create} to add, ${validPlan.update} to change, ${validPlan.delete} to delete`,
      );
    });

    it('renders button when url is found', () => {
      expect(findLogButton().exists()).toBe(true);
      expect(findLogButton().text()).toEqual('View full log');
    });
  });

  describe('invalidPlan', () => {
    beforeEach(() => {
      mountWrapper({ plan: invalidPlan });
    });

    it('diplays generic header since job_name is missing', () => {
      expect(wrapper.text()).toContain('A Terraform report was generated in your pipelines.');
    });

    it('diplays generic error since report values are missing', () => {
      expect(wrapper.text()).toContain('Generating the report caused an error.');
    });

    it('does not render button because url is missing', () => {
      expect(findLogButton().exists()).toBe(false);
    });
  });
});

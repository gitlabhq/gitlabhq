import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Step3 from '~/groups/settings/create_organization/components/steps/step_3.vue';
import BaseStep from '~/groups/settings/create_organization/components/steps/base_step.vue';

describe('ReconciliationStep3', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(Step3, {
      stubs: {
        BaseStep,
      },
    });
  };

  const findBaseStep = () => wrapper.findComponent(BaseStep);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders step title', () => {
      expect(findBaseStep().props('title')).toBe('Confirm your organization');
    });

    it('renders step description', () => {
      expect(
        wrapper
          .findByText(
            'After you confirm your organization structure, your data will be transferred to your organization.',
          )
          .exists(),
      ).toBe(true);
    });
  });
});

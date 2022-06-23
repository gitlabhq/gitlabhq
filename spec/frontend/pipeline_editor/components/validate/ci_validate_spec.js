import { GlButton, GlDropdown, GlIcon, GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CiValidate, { i18n } from '~/pipeline_editor/components/validate/ci_validate.vue';
import ValidatePipelinePopover from '~/pipeline_editor/components/popovers/validate_pipeline_popover.vue';
import { mockSimulatePipelineHelpPagePath } from '../../mock_data';

describe('Pipeline Editor Validate Tab', () => {
  let wrapper;

  const createComponent = ({ stubs } = {}) => {
    wrapper = shallowMount(CiValidate, {
      provide: {
        validateTabIllustrationPath: '/path/to/img',
        simulatePipelineHelpPagePath: mockSimulatePipelineHelpPagePath,
      },
      stubs,
    });
  };

  const findCta = () => wrapper.findComponent(GlButton);
  const findHelpIcon = () => wrapper.findComponent(GlIcon);
  const findPipelineSource = () => wrapper.findComponent(GlDropdown);
  const findPopover = () => wrapper.findComponent(GlPopover);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent({ stubs: { GlPopover, ValidatePipelinePopover } });
    });

    it('renders disabled pipeline source dropdown', () => {
      expect(findPipelineSource().exists()).toBe(true);
      expect(findPipelineSource().attributes('text')).toBe(i18n.pipelineSourceDefault);
      expect(findPipelineSource().attributes('disabled')).toBe('true');
    });

    it('renders CTA', () => {
      expect(findCta().exists()).toBe(true);
      expect(findCta().text()).toBe(i18n.cta);
    });

    it('popover is set to render when hovering over help icon', () => {
      expect(findPopover().props('target')).toBe(findHelpIcon().attributes('id'));
      expect(findPopover().props('triggers')).toBe('hover focus');
    });
  });
});

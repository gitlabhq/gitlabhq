import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import DownstreamPipelineDropdown from '~/ci/pipeline_mini_graph/downstream_pipeline_dropdown.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { singlePipeline } from './mock_data';

describe('Downstream Pipeline Dropdown', () => {
  let wrapper;

  const defaultProps = {
    pipeline: singlePipeline,
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(DownstreamPipelineDropdown, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        ...defaultProps,
      },
    });
  };

  const findDropdownButton = () => wrapper.findComponent(CiIcon);

  describe('dropdown button', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should pass the status to ci icon', () => {
      expect(findDropdownButton().props('status')).toBe(singlePipeline.detailedStatus);

      expect(findDropdownButton().props('status')).toEqual(
        expect.objectContaining({
          icon: expect.any(String),
          detailsPath: expect.any(String),
        }),
      );
    });

    it('should have the correct title assigned for the tooltip', () => {
      expect(findDropdownButton().attributes('title')).toBe('trigger-downstream - passed');
    });
  });
});

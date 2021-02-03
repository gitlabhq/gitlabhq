import { shallowMount } from '@vue/test-utils';
import PipelineEditorHeader from '~/pipeline_editor/components/header/pipeline_editor_header.vue';
import ValidationSegment from '~/pipeline_editor/components/header/validation_segment.vue';

import { mockLintResponse } from '../../mock_data';

describe('Pipeline editor header', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineEditorHeader, {
      props: {
        ciConfigData: mockLintResponse,
        isCiConfigDataLoading: false,
      },
    });
  };

  const findValidationSegment = () => wrapper.findComponent(ValidationSegment);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });
    it('renders the validation segment', () => {
      expect(findValidationSegment().exists()).toBe(true);
    });
  });
});

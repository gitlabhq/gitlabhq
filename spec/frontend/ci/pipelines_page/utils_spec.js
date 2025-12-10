import { updatePipelineNodes } from '~/ci/pipelines_page/utils';
import { mockPipelineUpdateResponse, mockPipelines } from './mock_data';

describe('Pipelines utility functions', () => {
  describe('updatePipelineNodes', () => {
    it('updates the pipeline status from passed with warnings to running', () => {
      const pipeline = mockPipelines[0];
      const unchangedPipeline = mockPipelines[1];

      expect(pipeline.detailedStatus.icon).toBe('status_warning');

      const updatedPipelines = updatePipelineNodes(
        mockPipelines,
        mockPipelineUpdateResponse.data.ciPipelineStatusesUpdated,
      );

      expect(updatedPipelines[0].detailedStatus.icon).toBe('status_running');
      expect(updatedPipelines[1]).toEqual(unchangedPipeline);
    });
  });
});

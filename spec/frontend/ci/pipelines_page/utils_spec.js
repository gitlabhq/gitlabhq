import { updatePipelineNodes } from '~/ci/pipelines_page/utils';
import { mockPipelineUpdateResponse, mockPipelines, mockNewPipeline } from './mock_data';

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

    it('merges a new pipeline if it does not previously exist', () => {
      const initialLength = mockPipelines.length;
      const updatedPipelines = updatePipelineNodes(mockPipelines, mockNewPipeline);

      expect(updatedPipelines).toHaveLength(initialLength + 1);
      expect(updatedPipelines[0]).toEqual(mockNewPipeline);
      expect(updatedPipelines.slice(1)).toEqual(mockPipelines);
    });
  });
});

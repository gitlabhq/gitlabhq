import { updatePipelineNodes } from '~/ci/merge_requests/utils';
import { mockPipelineUpdateResponse, mockPipelines } from './mock_data';

describe('Pipelines utility functions', () => {
  describe('updatePipelineNodes', () => {
    it('merges subscription update correctly when pipeline transitions from completed to running', () => {
      const pipeline = mockPipelines[0];
      const unchangedPipeline = mockPipelines[1];

      // Before update: pipeline is completed with warnings
      expect(pipeline.detailedStatus.icon).toBe('status_warning');
      expect(pipeline.detailedStatus.name).toBe('SUCCESS_WITH_WARNINGS');
      expect(pipeline.detailedStatus.label).toBe('passed with warnings');
      expect(pipeline.duration).toBe(17);
      expect(pipeline.finishedAt).toBe('2025-09-25T16:24:02Z');
      expect(pipeline.retryable).toBe(true);
      expect(pipeline.cancelable).toBe(false);
      expect(pipeline.stages.nodes).toHaveLength(3);
      expect(pipeline.stages.nodes[0].detailedStatus.icon).toBe('status_success');

      const updatedPipelines = updatePipelineNodes(
        mockPipelines,
        mockPipelineUpdateResponse.data.ciPipelineStatusUpdated,
      );

      // After subscription update: pipeline is now running with updated status and stages
      expect(updatedPipelines[0].detailedStatus.icon).toBe('status_running');
      expect(updatedPipelines[0].detailedStatus.name).toBe('RUNNING');
      expect(updatedPipelines[0].detailedStatus.label).toBe('running');
      expect(updatedPipelines[0].duration).toBeNull();
      expect(updatedPipelines[0].finishedAt).toBeNull();
      expect(updatedPipelines[0].retryable).toBe(false);
      expect(updatedPipelines[0].cancelable).toBe(true);

      expect(updatedPipelines[0].stages.nodes).toHaveLength(3);
      expect(updatedPipelines[0].stages.nodes[0].name).toBe('build');
      expect(updatedPipelines[0].stages.nodes[0].detailedStatus.icon).toBe('status_running');
      expect(updatedPipelines[0].stages.nodes[0].detailedStatus.tooltip).toBe('running');
      expect(updatedPipelines[0].stages.nodes[1].detailedStatus.icon).toBe('status_created');
      expect(updatedPipelines[0].stages.nodes[2].detailedStatus.icon).toBe('status_created');

      expect(updatedPipelines[1]).toEqual(unchangedPipeline);
    });
  });
});

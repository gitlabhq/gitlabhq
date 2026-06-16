import {
  updatePipelineInQueryResult,
  updateDownstreamPipelineInList,
} from '~/ci/merge_requests/utils';
import {
  mockPipelineUpdateResponse,
  mockPipelines,
  generateMockPipeline,
  generateMockDownstreamPipeline,
} from './mock_data';

const wrapAsQueryResult = (nodes) => ({
  project: {
    mergeRequest: {
      pipelines: { nodes },
    },
  },
});

const getNodes = (queryResult) => queryResult.project.mergeRequest.pipelines.nodes;

describe('Pipelines utility functions', () => {
  describe('updatePipelineInQueryResult', () => {
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

      const queryResult = wrapAsQueryResult(mockPipelines);
      const updatedResult = updatePipelineInQueryResult(
        queryResult,
        mockPipelineUpdateResponse.data.ciPipelineStatusUpdated,
      );
      const updatedPipelines = getNodes(updatedResult);

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

    it('returns the input unchanged when there are no pipelines to patch', () => {
      const queryResult = wrapAsQueryResult([]);
      const result = updatePipelineInQueryResult(
        queryResult,
        mockPipelineUpdateResponse.data.ciPipelineStatusUpdated,
      );
      expect(result).toBe(queryResult);
    });
  });

  describe('updateDownstreamPipelineInList', () => {
    const downstreamRunning = generateMockDownstreamPipeline({ id: '100', status: 'RUNNING' });
    const downstreamPending = generateMockDownstreamPipeline({ id: '200', status: 'PENDING' });

    const parentPipeline = {
      ...generateMockPipeline({ id: '1' }),
      graphqlId: 'gid://gitlab/Ci::Pipeline/1',
      downstream: {
        nodes: [downstreamRunning, downstreamPending],
        __typename: 'PipelineConnection',
      },
    };

    const otherPipeline = {
      ...generateMockPipeline({ id: '2' }),
      graphqlId: 'gid://gitlab/Ci::Pipeline/2',
    };

    const pipelines = [parentPipeline, otherPipeline];

    const newStatus = {
      id: 'success-100-100',
      name: 'SUCCESS',
      icon: 'status_success',
      text: 'Passed',
      tooltip: 'passed',
      label: 'passed',
      __typename: 'DetailedStatus',
    };

    const updatedDownstream = { id: downstreamRunning.id, detailedStatus: newStatus };

    it('updates the correct downstream pipeline status', () => {
      const result = updateDownstreamPipelineInList(pipelines, {
        parentGraphqlId: parentPipeline.graphqlId,
        updatedDownstream,
      });

      const updatedNodes = result[0].downstream.nodes;
      expect(updatedNodes[0].detailedStatus).toEqual(newStatus);
      expect(updatedNodes[1]).toEqual(downstreamPending);
      expect(result[1]).toBe(otherPipeline);
    });

    it('returns the input unchanged when parent not found', () => {
      const result = updateDownstreamPipelineInList(pipelines, {
        parentGraphqlId: 'gid://gitlab/Ci::Pipeline/999',
        updatedDownstream,
      });

      expect(result).toEqual(pipelines);
    });

    it('returns the input unchanged when downstream not found', () => {
      const result = updateDownstreamPipelineInList(pipelines, {
        parentGraphqlId: parentPipeline.graphqlId,
        updatedDownstream: { id: 'gid://gitlab/Ci::Pipeline/999', detailedStatus: newStatus },
      });

      expect(result).toEqual(pipelines);
    });

    it('does not mutate the original pipelines array', () => {
      const originalStatus = { ...downstreamRunning.detailedStatus };

      updateDownstreamPipelineInList(pipelines, {
        parentGraphqlId: parentPipeline.graphqlId,
        updatedDownstream,
      });

      expect(pipelines[0].downstream.nodes[0].detailedStatus).toEqual(originalStatus);
    });

    it('preserves other properties of the downstream pipeline', () => {
      const result = updateDownstreamPipelineInList(pipelines, {
        parentGraphqlId: parentPipeline.graphqlId,
        updatedDownstream,
      });

      const downstream = result[0].downstream.nodes[0];
      expect(downstream.id).toBe(downstreamRunning.id);
      expect(downstream.name).toBe(downstreamRunning.name);
      expect(downstream.project).toEqual(downstreamRunning.project);
    });

    it('returns the input unchanged for empty array', () => {
      const result = updateDownstreamPipelineInList([], {
        parentGraphqlId: parentPipeline.graphqlId,
        updatedDownstream,
      });

      expect(result).toEqual([]);
    });

    it('handles a pipeline with no downstream nodes', () => {
      const pipelineNoDownstream = {
        ...generateMockPipeline({ id: '3' }),
        graphqlId: 'gid://gitlab/Ci::Pipeline/3',
        downstream: { nodes: [], __typename: 'PipelineConnection' },
      };

      const result = updateDownstreamPipelineInList([pipelineNoDownstream], {
        parentGraphqlId: pipelineNoDownstream.graphqlId,
        updatedDownstream: { id: 'gid://gitlab/Ci::Pipeline/100', detailedStatus: newStatus },
      });

      expect(result).toEqual([pipelineNoDownstream]);
    });
  });
});

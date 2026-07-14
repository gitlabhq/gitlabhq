import { updateDownstreamPipelineInList } from '~/ci/merge_requests/utils';
import { generateMockPipeline, generateMockDownstreamPipeline } from './mock_data';

describe('Pipelines utility functions', () => {
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

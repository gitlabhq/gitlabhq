import { transform } from '~/glql/core/transformer/data';
import * as functions from '~/glql/core/transformer/functions';

describe('GLQL Data Transformer', () => {
  describe('transform', () => {
    it.each`
      sourceType
      ${'issues'}
      ${'mergeRequests'}
    `('transforms data for $sourceType source', ({ sourceType }) => {
      const mockData = {
        project: {
          [sourceType]: {
            nodes: [
              { id: '1', title: 'Lorem ipsum', labels: { nodes: [{ title: 'bug' }] } },
              { id: '2', title: 'Dolor sit amet', labels: { nodes: [{ title: 'feature' }] } },
            ],
          },
        },
      };
      const mockConfig = {
        fields: [
          { key: 'title', name: 'title' },
          {
            key: 'labels_bug',
            name: 'labels',
            transform: functions.getFunction('labels').getTransformer('labels_bug', 'bug'),
          },
        ],
      };

      const result = transform(mockData, mockConfig);

      expect(result).toEqual({
        nodes: [
          {
            id: '1',
            title: 'Lorem ipsum',
            labels_bug: { nodes: [{ title: 'bug' }] },
            labels: { nodes: [] },
          },
          {
            id: '2',
            title: 'Dolor sit amet',
            labels_bug: { nodes: [] },
            labels: { nodes: [{ title: 'feature' }] },
          },
        ],
      });
    });
  });
});

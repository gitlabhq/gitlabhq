import { transform } from '~/glql/core/transformer/data';
import * as functions from '~/glql/core/transformer/functions';

describe('GLQL Data Transformer', () => {
  describe('transform', () => {
    it('transforms data for issues source', () => {
      const mockData = {
        project: {
          issues: {
            nodes: [
              { id: '1', title: 'Issue 1', labels: { nodes: [{ title: 'bug' }] } },
              { id: '2', title: 'Issue 2', labels: { nodes: [{ title: 'feature' }] } },
            ],
          },
        },
      };
      const mockConfig = {
        source: 'issues',
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
            title: 'Issue 1',
            labels_bug: { nodes: [{ title: 'bug' }] },
            labels: { nodes: [] },
          },
          {
            id: '2',
            title: 'Issue 2',
            labels_bug: { nodes: [] },
            labels: { nodes: [{ title: 'feature' }] },
          },
        ],
      });
    });
  });
});

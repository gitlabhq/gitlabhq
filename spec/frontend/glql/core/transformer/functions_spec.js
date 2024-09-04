import * as functions from '~/glql/core/transformer/functions';

describe('GLQL Transformer Functions', () => {
  describe('labels', () => {
    it('returns correct field name', () => {
      const labelsFunction = functions.getFunction('labels');
      expect(labelsFunction.getFieldName('bug', 'feature')).toBe('labels');
    });

    it('returns correct field label', () => {
      const labelsFunction = functions.getFunction('labels');
      expect(labelsFunction.getFieldLabel('bug', 'feature')).toBe('Labels: Bug, Feature');
    });

    it('transforms data correctly', () => {
      const labelsFunction = functions.getFunction('labels');
      const transformer = labelsFunction.getTransformer('custom_key', 'bug', 'feature');

      const mockData = {
        nodes: [
          { id: '1', labels: { nodes: [{ title: 'bug' }, { title: 'critical' }] } },
          { id: '2', labels: { nodes: [{ title: 'feature' }, { title: 'enhancement' }] } },
        ],
      };

      const result = transformer(mockData);

      expect(result).toEqual({
        nodes: [
          {
            id: '1',
            custom_key: { nodes: [{ title: 'bug' }] },
            labels: { nodes: [{ title: 'critical' }] },
          },
          {
            id: '2',
            custom_key: { nodes: [{ title: 'feature' }] },
            labels: { nodes: [{ title: 'enhancement' }] },
          },
        ],
      });
    });
  });
});

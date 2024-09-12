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

    describe('getTransformer', () => {
      const getTransformer = (values, mockData) => {
        const labelsFunction = functions.getFunction('labels');
        const transformer = labelsFunction.getTransformer('custom_key', ...values);

        return transformer(mockData);
      };

      it('allows 10 values to be provided', () => {
        const values = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
        const mockData = { nodes: [{ id: '1', labels: { nodes: [] } }] };

        expect(() => getTransformer(values, mockData)).not.toThrow();
      });

      it('throws an error when more than 10 values are provided', () => {
        const values = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'];
        const mockData = { nodes: [{ id: '1', labels: { nodes: [] } }] };

        expect(() => getTransformer(values, mockData)).toThrow(
          'Function `labels` can only take a maximum of 10 parameters.',
        );
      });

      it('transforms data correctly', () => {
        const values = ['bug', 'feature*', '*maintenance*'];
        const mockData = {
          nodes: [
            {
              id: '1',
              labels: {
                nodes: [{ title: 'bug::closed' }, { title: 'bug' }, { title: 'critical' }],
              },
            },
            {
              id: '2',
              labels: {
                nodes: [
                  { title: 'feature-request' },
                  { title: 'enhancement' },
                  { title: 'a-maintenance-b' },
                ],
              },
            },
          ],
        };

        const result = getTransformer(values, mockData);

        expect(result).toEqual({
          nodes: [
            {
              id: '1',
              custom_key: { nodes: [{ title: 'bug' }] },
              labels: { nodes: [{ title: 'bug::closed' }, { title: 'critical' }] },
            },
            {
              id: '2',
              custom_key: { nodes: [{ title: 'feature-request' }, { title: 'a-maintenance-b' }] },
              labels: { nodes: [{ title: 'enhancement' }] },
            },
          ],
        });
      });
    });
  });
});

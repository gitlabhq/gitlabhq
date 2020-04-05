import { generateAnnotationsSeries } from '~/monitoring/components/charts/annotations';
import { deploymentData } from '../../mock_data';

describe('annotations spec', () => {
  describe('generateAnnotationsSeries', () => {
    it('default options', () => {
      const annotations = generateAnnotationsSeries();
      expect(annotations).toEqual([]);
    });

    it('with deployments', () => {
      const annotations = generateAnnotationsSeries(deploymentData);

      expect(annotations).toEqual(
        expect.objectContaining({
          type: 'scatter',
          yAxisIndex: 1,
          data: expect.any(Array),
        }),
      );

      annotations.data.forEach(annotation => {
        expect(annotation).toEqual(expect.any(Object));
      });
    });
  });
});

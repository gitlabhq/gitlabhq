import { generateAnnotationsSeries } from '~/monitoring/components/charts/annotations';
import { deploymentData, annotationsData } from '../../mock_data';

describe('annotations spec', () => {
  describe('generateAnnotationsSeries', () => {
    it('with default options', () => {
      const annotations = generateAnnotationsSeries();

      expect(annotations).toEqual(
        expect.objectContaining({
          type: 'scatter',
          yAxisIndex: 1,
          data: [],
          markLine: {
            data: [],
            symbol: 'none',
            silent: true,
          },
        }),
      );
    });

    it('when only deployments data is passed', () => {
      const annotations = generateAnnotationsSeries({ deployments: deploymentData });

      expect(annotations).toEqual(
        expect.objectContaining({
          type: 'scatter',
          yAxisIndex: 1,
          data: expect.any(Array),
          markLine: {
            data: [],
            symbol: 'none',
            silent: true,
          },
        }),
      );

      annotations.data.forEach((annotation) => {
        expect(annotation).toEqual(expect.any(Object));
      });

      expect(annotations.data).toHaveLength(deploymentData.length);
    });

    it('when only annotations data is passed', () => {
      const annotations = generateAnnotationsSeries({
        annotations: annotationsData,
      });

      expect(annotations).toEqual(
        expect.objectContaining({
          type: 'scatter',
          yAxisIndex: 1,
          data: expect.any(Array),
          markLine: expect.any(Object),
          markPoint: expect.any(Object),
        }),
      );

      annotations.markLine.data.forEach((annotation) => {
        expect(annotation).toEqual(expect.any(Object));
      });

      expect(annotations.data).toHaveLength(0);
      expect(annotations.markLine.data).toHaveLength(annotationsData.length);
      expect(annotations.markPoint.data).toHaveLength(annotationsData.length);
    });

    it('when deployments and annotations data is passed', () => {
      const annotations = generateAnnotationsSeries({
        deployments: deploymentData,
        annotations: annotationsData,
      });

      expect(annotations).toEqual(
        expect.objectContaining({
          type: 'scatter',
          yAxisIndex: 1,
          data: expect.any(Array),
          markLine: expect.any(Object),
          markPoint: expect.any(Object),
        }),
      );

      annotations.markLine.data.forEach((annotation) => {
        expect(annotation).toEqual(expect.any(Object));
      });

      expect(annotations.data).toHaveLength(deploymentData.length);
      expect(annotations.markLine.data).toHaveLength(annotationsData.length);
      expect(annotations.markPoint.data).toHaveLength(annotationsData.length);
    });
  });
});

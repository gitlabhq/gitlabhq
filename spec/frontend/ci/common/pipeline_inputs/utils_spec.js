import { getSkeletonRectProps } from '~/ci/common/pipeline_inputs/utils';

describe('Skeleton utils', () => {
  describe('getSkeletonRectProps', () => {
    it.each`
      columnIndex | rowIndex | expectedX  | expectedY
      ${0}        | ${0}     | ${'0%'}    | ${0}
      ${1}        | ${0}     | ${'25.5%'} | ${0}
      ${2}        | ${0}     | ${'51%'}   | ${0}
      ${3}        | ${0}     | ${'76.5%'} | ${0}
      ${0}        | ${1}     | ${'0%'}    | ${10}
      ${2}        | ${3}     | ${'51%'}   | ${30}
    `(
      'calculates correct position for col $columnIndex, row $rowIndex',
      ({ columnIndex, rowIndex, expectedX, expectedY }) => {
        const result = getSkeletonRectProps(columnIndex, rowIndex);

        expect(result.x).toBe(expectedX);
        expect(result.y).toBe(expectedY);
        expect(result.width).toBe('23%');
        expect(result.height).toBe(6);
        expect(result.rx).toBe(2);
        expect(result.ry).toBe(2);
      },
    );
  });
});

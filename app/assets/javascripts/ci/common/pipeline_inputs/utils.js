/**
 * Generates skeleton rect props for the skeleton loader based on column and row indices
 *
 * @param {Number} columnIndex - The column index (0-based)
 * @param {Number} rowIndex - The row index (0-based)
 * @returns {Object} - The props for the skeleton rect
 */
export const getSkeletonRectProps = (columnIndex, rowIndex) => {
  return {
    x: `${columnIndex * 25.5}%`,
    y: rowIndex * 10,
    width: '23%',
    height: 6,
    rx: 2,
    ry: 2,
  };
};

import { isEqual } from 'lodash';

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

/**
 * Formats a value for display in the input preview
 * @param {*} value - The value to format
 * @returns {string} - Formatted string representation
 */
export function formatValue(value) {
  if (value === null) return 'null';
  if (value === undefined) return 'undefined';
  if (typeof value === 'string') return `"${value}"`;
  if (typeof value === 'object') return JSON.stringify(value);
  return String(value);
}

/**
 * Checks if an input value has changed from its default
 * @param {*} value - Current value
 * @param {*} defaultValue - Default value
 * @returns {boolean} - True if values are different
 */
export function hasValueChanged(value, defaultValue) {
  if (typeof value === 'object' || typeof defaultValue === 'object') {
    return !isEqual(value, defaultValue);
  }
  return value !== defaultValue;
}

/**
 * Formats value lines for diff display
 * @param {Object} input - Input object with value, default, etc.
 * @param {boolean} isChanged - Whether the value has changed
 * @returns {Array} - Array of line objects
 */
export function formatValueLines(input, isChanged) {
  const lines = [];
  const formattedValue = formatValue(input.value);
  const formattedDefault = formatValue(input.default);

  if (isChanged) {
    lines.push({
      // eslint-disable-next-line @gitlab/require-i18n-strings
      content: `-   value: ${formattedDefault}`,
      type: 'old',
    });
    lines.push({
      // eslint-disable-next-line @gitlab/require-i18n-strings
      content: `+   value: ${formattedValue}`,
      type: 'new',
    });
  } else {
    lines.push({
      // eslint-disable-next-line @gitlab/require-i18n-strings
      content: `    value: ${formattedValue}`,
      type: '',
    });
  }

  return lines;
}

/**
 * Formats metadata lines (type, description)
 * @param {Object} input - Input object
 * @returns {Array} - Array of line objects
 */
export function formatMetadataLines(input) {
  const lines = [];

  if (input.type) {
    lines.push({
      // eslint-disable-next-line @gitlab/require-i18n-strings
      content: `    type: "${input.type}"`,
      type: '',
    });
  }

  if (input.description) {
    lines.push({
      // eslint-disable-next-line @gitlab/require-i18n-strings
      content: `    description: "${input.description}"`,
      type: '',
    });
  }

  return lines;
}

/**
 * Formats a single input into display lines
 * @param {Object} input - Input object
 * @returns {Array} - Array of line objects
 */
export function formatInputLines(input) {
  const lines = [];
  const isChanged = hasValueChanged(input.value, input.default);

  lines.push({
    content: `${input.name}:`,
    type: '',
  });

  lines.push(...formatValueLines(input, isChanged));

  lines.push(...formatMetadataLines(input));

  lines.push({
    content: '',
    type: '',
  });

  return lines;
}

/**
 * Formats all inputs into display lines
 * @param {Array} inputs - Array of input objects
 * @returns {Array} - Array of line objects for display
 */
export function formatInputsForDisplay(inputs) {
  return inputs.flatMap(formatInputLines);
}

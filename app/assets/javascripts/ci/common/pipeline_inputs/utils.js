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

/**
 * Comparison operators for evaluating conditions
 */
const comparisonOperators = {
  equals: (a, b) => a === b,
  not_equals: (a, b) => a !== b,
  greater_than: (a, b) => Number(a) > Number(b),
  less_than: (a, b) => Number(a) < Number(b),
  greater_than_or_equal: (a, b) => Number(a) >= Number(b),
  less_than_or_equal: (a, b) => Number(a) <= Number(b),
};

/**
 * Logical operators for combining conditions
 */
const logicalOperators = {
  AND: (children, evaluateFn) => children.every(evaluateFn),
  OR: (children, evaluateFn) => children.some(evaluateFn),
  NOT: (children, evaluateFn) => children.length === 1 && !evaluateFn(children[0]),
};

/**
 * Gets the value of an input by name
 * @param {string} field - The input field name
 * @param {Array} inputs - Array of input objects
 * @returns {*} - The input value or undefined
 */
function getInputValue(field, inputs) {
  const input = inputs.find((i) => i.name === field);
  return input?.value;
}

/**
 * Evaluates a single condition against input values
 * @param {Object} condition - The condition with field, operator, and value
 * @param {Array} inputs - Array of input objects
 * @returns {Boolean} - Whether the condition is satisfied
 */
function evaluateCondition(condition, inputs) {
  const { field, operator, value } = condition;
  const inputValue = getInputValue(field, inputs);

  if (inputValue === undefined) {
    return false;
  }

  const operatorFn = comparisonOperators[operator];
  return operatorFn ? operatorFn(inputValue, value) : false;
}

/**
 * Evaluates a condition tree against current input values
 * @param {Object} conditions - The condition tree (either a single condition or logical operator)
 * @param {Array} inputs - Array of input objects with name, value, and isSelected properties
 * @returns {Boolean} - Whether the conditions are satisfied
 * @private
 */
function evaluateConditions(conditions, inputs) {
  function evaluate(node) {
    if (node.field) {
      return evaluateCondition(node, inputs);
    }

    if (node.operator && node.children) {
      const { operator, children } = node;

      if (!Array.isArray(children) || children.length === 0) {
        return false;
      }

      const operatorFn = logicalOperators[operator];
      return operatorFn ? operatorFn(children, evaluate) : false;
    }

    return false;
  }

  return evaluate(conditions);
}

/**
 * Finds the first matching rule from an array of rules
 * @param {Array} rules - Array of rule objects with conditionTree, options, and default
 * @param {Array} inputs - Array of input objects
 * @returns {Object|undefined} - The matching rule or undefined
 */
export function findMatchingRule(rules, inputs) {
  if (!Array.isArray(rules)) {
    return undefined;
  }

  return rules.find((rule) => {
    if (!rule.conditionTree || Object.keys(rule.conditionTree).length === 0) {
      return true;
    }

    return evaluateConditions(rule.conditionTree, inputs);
  });
}

/**
 * Creates a map of saved input values for quick lookup
 * @param {Array} savedInputs - Array of saved input objects with name and value
 * @returns {Object} - Map of input names to values
 * @private
 */
function createSavedInputsMap(savedInputs) {
  return Object.fromEntries(savedInputs.map(({ name, value }) => [name, value]));
}

/**
 * Processes a single input with saved values and preselection settings
 * @param {Object} input - The input object from GraphQL
 * @param {Object} savedInputsMap - Map of saved input values
 * @param {boolean} preselectAllInputs - Whether to preselect all inputs
 * @returns {Object} - Processed input with additional properties
 * @private
 */
function processInput(input, savedInputsMap, preselectAllInputs) {
  const hasSavedValue = savedInputsMap[input.name] !== undefined;
  return {
    ...input,
    savedValue: savedInputsMap[input.name],
    value: hasSavedValue ? savedInputsMap[input.name] : input.default,
    isSelected: hasSavedValue || preselectAllInputs,
    hasRules: Boolean(input.rules?.length),
  };
}

/**
 * Processes query inputs with saved values and determines if dynamic rules exist
 * @param {Array} queryInputs - Raw inputs from GraphQL query
 * @param {Array} savedInputs - Array of saved input objects
 * @param {boolean} preselectAllInputs - Whether to preselect all inputs
 * @returns {Object} - Object with processedInputs and hasDynamicRules flag
 */
export function processQueryInputs(queryInputs, savedInputs, preselectAllInputs) {
  const savedInputsMap = createSavedInputsMap(savedInputs);

  const processedInputs = queryInputs.map((input) =>
    processInput(input, savedInputsMap, preselectAllInputs),
  );

  const hasDynamicRules = processedInputs.some((input) => input.hasRules);

  return {
    processedInputs,
    hasDynamicRules,
  };
}

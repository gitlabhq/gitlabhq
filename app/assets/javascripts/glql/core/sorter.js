const healthStatuses = {
  onTrack: 1,
  needsAttention: 2,
  atRisk: 3,
};

const states = {
  opened: 1,
  closed: 2,
  merged: 3,
};

const statusCategories = {
  triage: 1,
  to_do: 2,
  in_progress: 3,
  done: 4,
  canceled: 5,
};

const sortFieldsByType = {
  Issue: 'title',
  Epic: 'title',
  Label: 'title',
  UserCore: 'username',
  MergeRequestAuthor: 'username',
  MergeRequestReviewer: 'username',
  MergeRequestAssignee: 'username',
  Project: 'nameWithNamespace',
};

function valueByType(field, type) {
  return field[sortFieldsByType[type]];
}

function valueByFieldName(fieldValue, fieldName) {
  switch (fieldName) {
    case 'healthStatus':
      return healthStatuses[fieldValue];
    case 'state':
      return states[fieldValue];
    case 'status':
      return statusCategories[fieldValue.category];
    case 'milestone':
    case 'iteration':
      return new Date(fieldValue.dueDate);
    default:
      return null;
  }
}

function value(fieldValue, fieldName = null) {
  if (fieldValue === null || typeof fieldValue === 'undefined') return null;

  const val =
    // eslint-disable-next-line no-underscore-dangle
    valueByType(fieldValue, fieldValue.__typename) || valueByFieldName(fieldValue, fieldName);
  if (val) return val;

  if (typeof fieldValue === 'boolean' || typeof fieldValue === 'number') return fieldValue;
  if (typeof fieldValue === 'string' && String(Number(fieldValue)) === fieldValue)
    return Number(fieldValue);
  if (typeof fieldValue === 'object' && Array.isArray(fieldValue.nodes))
    return fieldValue.nodes.map(value).join(',') || null;

  if (typeof fieldValue === 'object') return fieldValue.title;
  if (
    typeof fieldValue === 'string' &&
    fieldValue.match(/^\d{4}-\d{2}-\d{2}/) /* date YYYY-MM-DD */
  )
    return new Date(fieldValue);

  return fieldValue;
}

export function sorterFor(fieldName, ascending = true) {
  return (a, b) => {
    const aValue = value(a[fieldName], fieldName);
    const bValue = value(b[fieldName], fieldName);
    const order = ascending ? 1 : -1;

    // sort null values to the end regardless of order
    if (aValue === null) return 1;
    if (bValue === null) return -1;
    if (aValue < bValue) return -order;
    if (aValue > bValue) return order;

    return 0;
  };
}

export function sortBy(items, fieldName, prevSortOptions = { fieldName: null, ascending: true }) {
  const newOptions = { ...prevSortOptions };
  if (newOptions.fieldName === fieldName) {
    newOptions.ascending = !newOptions.ascending;
  } else {
    newOptions.fieldName = fieldName;
    newOptions.ascending = true;
  }

  return {
    items: items.toSorted(sorterFor(newOptions.fieldName, newOptions.ascending)),
    options: newOptions,
  };
}

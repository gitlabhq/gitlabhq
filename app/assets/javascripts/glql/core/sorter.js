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
  Pipeline: 'name',
  CiJob: 'name',
  CiStage: 'name',
};

// Shared collator; 'base' sensitivity treats accented and cased variants as equal.
const collator = new Intl.Collator(undefined, { sensitivity: 'base' });

function valueByType(field, type) {
  return field[sortFieldsByType[type]];
}

function valueByFieldName(fieldValue, fieldName) {
  switch (fieldName) {
    case 'healthStatus':
      return healthStatuses[fieldValue];
    case 'state':
      return states[fieldValue];
    case 'status': {
      // Pipeline/CiJob statuses are plain strings; fall through to the string fallback
      if (typeof fieldValue !== 'object') return null;
      const categoryWeight = statusCategories[fieldValue.category] ?? 99;
      // Zero-pad so string comparison matches numeric order, then tie-break by name
      return `${String(categoryWeight).padStart(2, '0')}_${fieldValue.name ?? ''}`;
    }
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

    // value() also yields numbers, Dates and booleans, which compare by value
    if (typeof aValue === 'string' && typeof bValue === 'string') {
      return collator.compare(aValue, bValue) * order;
    }
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

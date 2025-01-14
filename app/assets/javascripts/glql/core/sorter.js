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

const sortFieldsByType = {
  Issue: 'title',
  Epic: 'title',
  Milestone: 'title',
  Label: 'title',
  UserCore: 'username',
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

export default class Sorter {
  #items;
  #options = {
    fieldName: null,
    ascending: true,
  };

  constructor(items) {
    this.#items = items;
  }

  get options() {
    return this.#options;
  }

  #sort() {
    return this.#items.sort(sorterFor(this.#options.fieldName, this.#options.ascending));
  }

  sortBy(fieldName) {
    if (this.#options.fieldName === fieldName) {
      this.#options.ascending = !this.#options.ascending;
    } else {
      this.#options.fieldName = fieldName;
      this.#options.ascending = true;
    }

    return this.#sort();
  }
}

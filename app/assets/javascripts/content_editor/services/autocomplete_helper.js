import { identity, memoize, isEmpty } from 'lodash';
import { initEmojiMap, getAllEmoji, searchEmoji } from '~/emoji';
import { newDate } from '~/lib/utils/datetime_utility';
import axios from '~/lib/utils/axios_utils';
import { COMMANDS } from '../constants';

export function defaultSorter(searchFields) {
  return (items, query) => {
    if (!query) return items;

    const sortOrdersMap = new WeakMap();

    items.forEach((item) => {
      const sortOrders = searchFields.map((searchField) => {
        const haystack = String(item[searchField]).toLocaleLowerCase();
        const needle = query.toLocaleLowerCase();

        const i = haystack.indexOf(needle);
        if (i < 0) return i;
        return Number.MAX_SAFE_INTEGER - i;
      });

      sortOrdersMap.set(item, Math.max(...sortOrders));
    });

    return items.sort((a, b) => sortOrdersMap.get(b) - sortOrdersMap.get(a));
  };
}

export function customSorter(sorter) {
  return (items) => items.sort(sorter);
}

const milestonesMap = new WeakMap();

function parseMilestone(milestone) {
  if (!milestone.title) {
    return milestone;
  }

  const dueDate = milestone.due_date ? newDate(milestone.due_date) : null;
  const expired = dueDate ? Date.now() > dueDate.getTime() : false;

  return {
    id: milestone.iid,
    title: milestone.title,
    expired,
    dueDate,
  };
}

function mapMilestone(milestone) {
  if (!milestonesMap.has(milestone)) {
    milestonesMap.set(milestone, parseMilestone(milestone));
  }

  return milestonesMap.get(milestone);
}

function sortMilestones(milestoneA, milestoneB) {
  const mappedA = mapMilestone(milestoneA);
  const mappedB = mapMilestone(milestoneB);

  // Move all expired milestones to the bottom.
  if (milestoneA.expired) return 1;
  if (milestoneB.expired) return -1;

  // Move milestones without due dates just above expired milestones.
  if (!milestoneA.dueDate) return 1;
  if (!milestoneB.dueDate) return -1;

  return mappedA.dueDate - mappedB.dueDate;
}

export function createDataSource({
  source,
  searchFields,
  filter,
  mapper = identity,
  sorter = defaultSorter(searchFields),
  cache = true,
  limit = 15,
  filterOnBackend = false,
}) {
  const fetchData = async (query) => {
    try {
      const queryOptions = filterOnBackend ? { params: { search: query } } : {};
      return source ? (await axios.get(source, queryOptions)).data : [];
    } catch {
      return [];
    }
  };

  const cacheTimeoutFn = () => (cache ? 0 : Math.floor(Date.now() / 1e4));
  const memoizedFetchData = memoize(fetchData, cacheTimeoutFn);

  return {
    search: async (query) => {
      let results = filterOnBackend ? await fetchData(query) : await memoizedFetchData();

      results = results.map(mapper);
      if (filter) results = filter(results, query);

      if (query) {
        results = results.filter((item) => {
          if (!searchFields.length) return true;
          return searchFields.some((field) =>
            String(item[field]).toLocaleLowerCase().includes(query.toLocaleLowerCase()),
          );
        });
      }

      return sorter(results, query).slice(0, limit);
    },
  };
}

export default class AutocompleteHelper {
  constructor({ dataSourceUrls, sidebarMediator }) {
    this.updateDataSources(dataSourceUrls);

    this.sidebarMediator = sidebarMediator;

    initEmojiMap();
  }

  updateDataSources(dataSourceUrls) {
    this.dataSourceUrls = !isEmpty(dataSourceUrls)
      ? dataSourceUrls
      : gl.GfmAutoComplete?.dataSources || {};

    this.getDataSource = memoize(this.#getDataSource, (referenceType, { command } = {}) => {
      if (referenceType === 'command') return referenceType;
      return referenceType + (command ? `_${command}` : '');
    });
  }

  #getDataSource = (referenceType, { command } = {}) => {
    const sources = {
      user: this.dataSourceUrls.members,
      issue: this.dataSourceUrls.issues,
      snippet: this.dataSourceUrls.snippets,
      label: this.dataSourceUrls.labels,
      epic: this.dataSourceUrls.epics,
      iteration: this.dataSourceUrls.iterations,
      milestone: this.dataSourceUrls.milestones,
      merge_request: this.dataSourceUrls.mergeRequests,
      vulnerability: this.dataSourceUrls.vulnerabilities,
      command: this.dataSourceUrls.commands,
      wiki: this.dataSourceUrls.wikis,
    };

    const searchFields = {
      user: ['username', 'name'],
      issue: ['iid', 'title'],
      snippet: ['id', 'title'],
      label: ['title'],
      epic: ['iid', 'title'],
      iteration: ['id', 'title'],
      vulnerability: ['id', 'title'],
      merge_request: ['iid', 'title'],
      milestone: ['title', 'iid'],
      command: ['name'],
      wiki: ['title'],
      emoji: [],
    };

    const filters = {
      label: (items) =>
        items.filter((item) => {
          if (command === COMMANDS.UNLABEL) return item.set;
          if (command === COMMANDS.LABEL) return !item.set;

          return true;
        }),
      user: (items) =>
        items.filter((item) => {
          const assigned = this.sidebarMediator?.store?.assignees.some(
            (assignee) => assignee.username === item.username,
          );
          const assignedReviewer = this.sidebarMediator?.store?.reviewers.some(
            (reviewer) => reviewer.username === item.username,
          );

          if (command === COMMANDS.ASSIGN) return !assigned;
          if (command === COMMANDS.ASSIGN_REVIEWER) return !assignedReviewer;
          if (command === COMMANDS.UNASSIGN) return assigned;
          if (command === COMMANDS.UNASSIGN_REVIEWER) return assignedReviewer;

          return true;
        }),
      emoji: (_, query) =>
        query
          ? searchEmoji(query)
          : getAllEmoji().map((emoji) => ({ emoji, fieldValue: emoji.name })),
    };

    const sorters = {
      milestone: customSorter(sortMilestones),
      default: defaultSorter(searchFields[referenceType]),
      // do not sort emoji
      emoji: customSorter(() => 0),
    };

    const mappers = {
      milestone: mapMilestone,
      default: identity,
    };

    return createDataSource({
      source: sources[referenceType],
      searchFields: searchFields[referenceType],
      mapper: mappers[referenceType] || mappers.default,
      sorter: sorters[referenceType] || sorters.default,
      filter: filters[referenceType],
      command,
    });
  };
}

import { s__ } from '~/locale';

export const getAssignees = (widgets) => {
  const found = widgets.find((widget) => widget.assignees !== undefined);
  if (found?.assignees) {
    return found.assignees?.nodes;
  }
  return [];
};

export const getLabels = (widgets) => {
  const found = widgets.find((widget) => widget.labels !== undefined);
  if (found?.labels) {
    return found.labels?.nodes;
  }
  return [];
};

export const getMilestone = (widgets) => {
  const found = widgets.find((widget) => widget.milestone !== undefined);
  if (found?.milestone) {
    return found.milestone;
  }
  return undefined;
};

export const getReactions = (widgets) => {
  const found = widgets.find((widget) => widget.awardEmoji !== undefined);
  if (found?.awardEmoji) {
    return found.awardEmoji.nodes;
  }
  return [];
};

const transformItem = (input) => {
  return {
    id: input.id,
    iid: input.iid,
    title: input.title,
    state: input.state,
    type: input.workItemType,
    reference: input.reference,
    author: input.author,
    assignees: getAssignees(input.widgets),
    labels: getLabels(input.widgets),
    milestone: getMilestone(input.widgets),
    webUrl: input.webUrl,
    confidential: input.confidential,
    reactions: getReactions(input.widgets),
  };
};

export const buildPools = (rawList, transformer = transformItem) => {
  const pools = {
    workItems: new Map(),
    labels: new Map(),
    users: new Map(),
    milestones: new Map(),
  };
  for (const raw of rawList) {
    const i = transformer(raw);

    const { labels, assignees, author, milestone } = i;
    const workItemId = i.id;

    // populate work item pool
    if (!pools.workItems.has(workItemId)) {
      pools.workItems.set(workItemId, {
        id: workItemId,
        labels: labels.map((l) => l.id),
        author: author.id,
        assignees: assignees?.map((a) => a.id) || [],
        ...i,
      });
    }

    // populate labels pool
    for (const label of labels) {
      const labelEntry = pools.labels.get(label.id) || { id: label.id, workItems: [], ...label };
      labelEntry.workItems.push(workItemId);
      pools.labels.set(label.id, labelEntry);
    }

    // populate users pool with authors
    const authorEntry = pools.users.get(author.id) || {
      id: author.id,
      authored: [],
      assigned: [],
      title: author.name,
      ...author,
    };
    authorEntry.authored.push(workItemId);
    pools.users.set(author.id, authorEntry);

    // add assignees to users pool
    if (assignees) {
      for (const assignee of assignees) {
        const assigneeEntry = pools.users.get(assignee.id) || {
          id: assignee.id,
          authored: [],
          assigned: [],
          title: author.name,
          ...assignee,
        };
        assigneeEntry.assigned.push(workItemId);
        pools.users.set(assignee.id, assigneeEntry);
      }
    }

    // populate milestones pool
    if (milestone) {
      const milestoneEntry = pools.milestones.get(milestone.id) || {
        id: milestone.id,
        workItems: [],
        ...milestone,
      };
      milestoneEntry.workItems.push(workItemId);
      pools.milestones.set(milestone.id, milestoneEntry);
    }
  }

  return {
    workItems: Object.fromEntries(pools.workItems),
    labels: Object.fromEntries(pools.labels),
    users: Object.fromEntries(pools.users),
    milestones: Object.fromEntries(pools.milestones),
  };
};

export const getGroupOptions = () => {
  return [
    { value: 'label', label: s__('WorkItem|Label') },
    { value: 'assignee', label: s__('WorkItem|Assignee') },
    { value: 'author', label: s__('WorkItem|Author') },
    { value: 'milestone', label: s__('WorkItem|Milestone') },
  ];
};

export const getPoolNameForGrouping = (groupingName) => {
  return {
    label: 'labels',
    assignee: 'users',
    author: 'users',
    milestone: 'milestones',
  }[groupingName];
};

function subtractArrays(arr1, arr2) {
  const setB = new Set(arr2);
  return arr1.filter((item) => !setB.has(item));
}

export const groupBy = ({ pool, itemIds, hideEmpty, noneLabel, itemsProperty = 'workItems' }) => {
  const groups = [];
  const includedItemIds = [];
  for (const i of Object.values(pool)) {
    groups.push({
      title: i.title,
      items: i[itemsProperty],
    });
    includedItemIds.push(...i[itemsProperty]);
  }
  const notIncluded = subtractArrays(itemIds, includedItemIds);
  return [{ title: noneLabel, items: notIncluded }, ...groups].filter((g) =>
    hideEmpty ? g.items.length > 0 : true,
  );
};

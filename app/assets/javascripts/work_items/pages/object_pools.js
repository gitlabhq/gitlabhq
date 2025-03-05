const getAssignees = (widgets) => {
  const found = widgets.find((widget) => widget.assignees !== undefined);
  if (found?.assignees) {
    return found.assignees?.nodes;
  }
  return [];
};

const getLabels = (widgets) => {
  const found = widgets.find((widget) => widget.labels !== undefined);
  if (found?.labels) {
    return found.labels?.nodes;
  }
  return [];
};

const getMilestone = (widgets) => {
  const found = widgets.find((widget) => widget.milestone !== undefined);
  if (found?.milestone) {
    return found.milestone;
  }
  return undefined;
};

const getIteration = (widgets) => {
  const found = widgets.find((widget) => widget.iteration !== undefined);
  if (found?.iteration) {
    return found.iteration;
  }
  return undefined;
};

const getHealthStatus = (widgets) => {
  const found = widgets.find((widget) => widget.healthStatus !== undefined);
  if (found?.healthStatus) {
    return found.healthStatus;
  }
  return undefined;
};

const getReactions = (widgets) => {
  const found = widgets.find((widget) => widget.awardEmoji !== undefined);
  if (found?.awardEmoji) {
    return found.awardEmoji.nodes;
  }
  return [];
};

const getWeight = (widgets) => {
  const found = widgets.find((widget) => widget.weight !== undefined);
  if (found?.weight) {
    return { value: found.weight };
  }
  return undefined;
};

const transformItem = (input) => {
  return {
    id: input.id,
    title: input.title,
    state: input.state,
    type: input.workItemType,
    reference: input.reference,
    author: input.author,
    assignees: getAssignees(input.widgets),
    labels: getLabels(input.widgets),
    milestone: getMilestone(input.widgets),
    iteration: getIteration(input.widgets),
    healthStatus: getHealthStatus(input.widgets),
    webUrl: input.webUrl,
    confidential: input.confidential,
    reactions: getReactions(input.widgets),
    weight: getWeight(input.widgets),
  };
};

export const buildPools = (rawList) => {
  const pools = {
    workItems: {},
    labels: {},
    users: {},
    milestones: {},
  };
  const flattened = rawList.map((raw) => transformItem(raw));
  for (const i of flattened) {
    const { labels, assignees, author, milestone } = i;
    if (pools.workItems[i.id] === undefined) {
      pools.workItems[i.id] = {
        id: i.id,
        labels: labels.map((l) => l.id),
        author: author.id,
        assignees: assignees?.map((a) => a.id) || [],
        ...i,
      };
    }
    for (const label of labels) {
      if (pools.labels[label.id]) {
        pools.labels[label.id].workItems.push(i.id);
      } else {
        pools.labels[label.id] = { id: label.id, workItems: [i.id], ...label };
      }
    }
    if (pools.users[author.id]) {
      pools.users[author.id].authored.push(i.id);
    } else {
      pools.users[author.id] = { id: author.id, authored: [i.id], assigned: [], ...author };
    }
    if (assignees) {
      for (const assignee of assignees) {
        if (pools.users[assignee.id]) {
          pools.users[assignee.id].assigned.push(i.id);
        } else {
          pools.users[assignee.id] = {
            id: assignee.id,
            authored: [],
            assigned: [i.id],
            ...assignee,
          };
        }
      }
    }
    if (milestone) {
      if (pools.milestones[milestone.id]) {
        pools.milestones[milestone.id].workItems.push(i.id);
      } else {
        pools.milestones[milestone.id] = {
          id: milestone.id,
          workItems: [i.id],
          ...milestone,
        };
      }
    }
  }
  return pools;
};

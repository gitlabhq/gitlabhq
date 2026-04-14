function cloneResponse(response) {
  return JSON.parse(JSON.stringify(response));
}

export function buildUpdateResponse({
  baseResponse,
  labelsFixture,
  assigneesFixture,
  milestoneFixture,
  input,
}) {
  const { labelsWidget, assigneesWidget, title } = input;

  if (labelsWidget) {
    const response = cloneResponse(labelsFixture);
    return response;
  }

  if (assigneesWidget) {
    const response = cloneResponse(assigneesFixture);
    return response;
  }

  if (title) {
    const response = cloneResponse(baseResponse);
    response.data.workItemUpdate.workItem.title = title;
    response.data.workItemUpdate.workItem.titleHtml = title;
    return response;
  }

  if (input.confidential !== undefined) {
    const response = cloneResponse(baseResponse);
    response.data.workItemUpdate.workItem.confidential = input.confidential;
    return response;
  }

  if (input.milestoneWidget) {
    return cloneResponse(milestoneFixture);
  }

  if (input.startAndDueDateWidget) {
    const response = cloneResponse(baseResponse);
    const { widgets } = response.data.workItemUpdate.workItem;
    const dateWidget = widgets.find((w) => w.type === 'START_AND_DUE_DATE');
    if (dateWidget) {
      Object.assign(dateWidget, {
        startDate: input.startAndDueDateWidget.startDate || null,
        dueDate: input.startAndDueDateWidget.dueDate || null,
        isFixed: input.startAndDueDateWidget.isFixed ?? dateWidget.isFixed,
      });
    }
    return response;
  }

  return cloneResponse(baseResponse);
}

export function getFirstWorkItem(listFixture) {
  const namespace = listFixture.data.namespace || listFixture.data.project;
  return namespace.workItems.nodes[0];
}

export function getLabelsFromFixture(labelsFixture) {
  const namespace = labelsFixture.data.namespace || labelsFixture.data.project;
  return namespace.labels.nodes;
}

export function getUsersFromFixture(usersFixture) {
  const namespace = usersFixture.data.namespace || usersFixture.data.project;
  return namespace.users || namespace.autocompleteUsers;
}

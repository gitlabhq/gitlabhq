import { set } from 'lodash';
import { produce } from 'immer';
import { findWidget } from '~/issues/list/utils';
import { pikadayToString } from '~/lib/utils/datetime_utility';
import { newWorkItemFullPath } from '../utils';
import {
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_COLOR,
  WIDGET_TYPE_ROLLEDUP_DATES,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_HEALTH_STATUS,
  WIDGET_TYPE_DESCRIPTION,
  WIDGET_TYPE_CRM_CONTACTS,
  NEW_WORK_ITEM_IID,
  CLEAR_VALUE,
} from '../constants';
import workItemByIidQuery from './work_item_by_iid.query.graphql';

const updateWidget = (draftData, widgetType, newData, nodePath) => {
  if (!newData) return;

  const widget = findWidget(widgetType, draftData.workspace.workItem);
  set(widget, nodePath, newData);
};

const updateHealthStatusWidget = (draftData, healthStatus) => {
  if (!healthStatus) return;

  const newValue = healthStatus === CLEAR_VALUE ? null : healthStatus;
  const widget = findWidget(WIDGET_TYPE_HEALTH_STATUS, draftData.workspace.workItem);
  set(widget, 'healthStatus', newValue);
};

const updateRolledUpDatesWidget = (draftData, rolledUpDates) => {
  if (!rolledUpDates) return;

  const dueDateFixed = rolledUpDates.dueDateFixed
    ? pikadayToString(rolledUpDates.dueDateFixed)
    : null;
  const startDateFixed = rolledUpDates.startDateFixed
    ? pikadayToString(rolledUpDates.startDateFixed)
    : null;

  const widget = findWidget(WIDGET_TYPE_ROLLEDUP_DATES, draftData.workspace.workItem);
  Object.assign(widget, {
    dueDate: dueDateFixed,
    dueDateFixed,
    dueDateIsFixed: rolledUpDates.dueDateIsFixed,
    startDate: startDateFixed,
    startDateFixed,
    startDateIsFixed: rolledUpDates.startDateIsFixed,
    __typename: 'WorkItemWidgetRolledupDates',
  });
};

export const updateNewWorkItemCache = (input, cache) => {
  const {
    healthStatus,
    fullPath,
    workItemType,
    assignees,
    color,
    title,
    description,
    confidential,
    labels,
    rolledUpDates,
    crmContacts,
  } = input;

  const query = workItemByIidQuery;
  const variables = {
    fullPath: newWorkItemFullPath(fullPath, workItemType),
    iid: NEW_WORK_ITEM_IID,
  };

  cache.updateQuery({ query, variables }, (sourceData) =>
    produce(sourceData, (draftData) => {
      const widgetUpdates = [
        {
          widgetType: WIDGET_TYPE_ASSIGNEES,
          newData: assignees,
          nodePath: 'assignees.nodes',
        },
        {
          widgetType: WIDGET_TYPE_LABELS,
          newData: labels,
          nodePath: 'labels.nodes',
        },
        {
          widgetType: WIDGET_TYPE_COLOR,
          newData: color,
          nodePath: 'color',
        },
        {
          widgetType: WIDGET_TYPE_DESCRIPTION,
          newData: description,
          nodePath: 'description',
        },
        {
          widgetType: WIDGET_TYPE_CRM_CONTACTS,
          newData: crmContacts,
          nodePath: 'contacts.nodes',
        },
      ];

      widgetUpdates.forEach(({ widgetType, newData, nodePath }) => {
        updateWidget(draftData, widgetType, newData, nodePath);
      });

      updateRolledUpDatesWidget(draftData, rolledUpDates);
      updateHealthStatusWidget(draftData, healthStatus);

      if (title) draftData.workspace.workItem.title = title;
      if (confidential !== undefined) draftData.workspace.workItem.confidential = confidential;
    }),
  );
};

export const workItemBulkEdit = (input) => {
  return {
    updatedIssueCount: input.ids.length,
  };
};

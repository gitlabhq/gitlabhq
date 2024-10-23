import { set, isEmpty } from 'lodash';
import { produce } from 'immer';
import { findWidget } from '~/issues/list/utils';
import { newDate, toISODateFormat } from '~/lib/utils/datetime_utility';
import { updateDraft } from '~/lib/utils/autosave';
import { getNewWorkItemAutoSaveKey, newWorkItemFullPath } from '../utils';
import {
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_COLOR,
  WIDGET_TYPE_ROLLEDUP_DATES,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_HEALTH_STATUS,
  WIDGET_TYPE_DESCRIPTION,
  WIDGET_TYPE_CRM_CONTACTS,
  WIDGET_TYPE_ITERATION,
  NEW_WORK_ITEM_IID,
} from '../constants';
import workItemByIidQuery from './work_item_by_iid.query.graphql';

// eslint-disable-next-line max-params
const updateWidget = (draftData, widgetType, newData, nodePath) => {
  /** set all other values other than when it is undefined including null/0 or empty array as well */
  /** we have to make sure we do not pass values when custom types are introduced */
  if (newData === undefined) return;

  const widget = findWidget(widgetType, draftData.workspace.workItem);
  set(widget, nodePath, newData);
};

const updateRolledUpDatesWidget = (draftData, rolledUpDates) => {
  if (!rolledUpDates) return;

  const dueDateFixed = rolledUpDates.dueDateFixed
    ? toISODateFormat(newDate(rolledUpDates.dueDateFixed))
    : null;
  const startDateFixed = rolledUpDates.startDateFixed
    ? toISODateFormat(newDate(rolledUpDates.startDateFixed))
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
    iteration,
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
          widgetType: WIDGET_TYPE_CRM_CONTACTS,
          newData: crmContacts,
          nodePath: 'contacts.nodes',
        },
        {
          widgetType: WIDGET_TYPE_DESCRIPTION,
          newData: description,
          nodePath: 'description',
        },
        {
          widgetType: WIDGET_TYPE_HEALTH_STATUS,
          newData: healthStatus,
          nodePath: 'healthStatus',
        },
        {
          widgetType: WIDGET_TYPE_ITERATION,
          newData: iteration,
          nodePath: 'iteration',
        },
      ];

      widgetUpdates.forEach(({ widgetType, newData, nodePath }) => {
        updateWidget(draftData, widgetType, newData, nodePath);
      });

      updateRolledUpDatesWidget(draftData, rolledUpDates);

      if (title) draftData.workspace.workItem.title = title;
      if (confidential !== undefined) draftData.workspace.workItem.confidential = confidential;
    }),
  );

  const newData = cache.readQuery({ query, variables });

  const autosaveKey = getNewWorkItemAutoSaveKey(fullPath, workItemType);

  const isQueryDataValid = !isEmpty(newData) && newData?.workspace?.workItem;

  if (isQueryDataValid && autosaveKey) {
    updateDraft(autosaveKey, JSON.stringify(newData));
  }
};

export const workItemBulkEdit = (input) => {
  return {
    updatedIssueCount: input.ids.length,
  };
};

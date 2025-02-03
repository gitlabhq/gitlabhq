import { set, isEmpty } from 'lodash';
import { produce } from 'immer';
import { findWidget } from '~/issues/list/utils';
import { newDate, toISODateFormat } from '~/lib/utils/datetime_utility';
import { updateDraft } from '~/lib/utils/autosave';
import { getParameterByName } from '~/lib/utils/url_utility';
import { getNewWorkItemAutoSaveKey, newWorkItemFullPath } from '../utils';
import {
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_COLOR,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_HEALTH_STATUS,
  WIDGET_TYPE_DESCRIPTION,
  WIDGET_TYPE_CRM_CONTACTS,
  WIDGET_TYPE_ITERATION,
  WIDGET_TYPE_WEIGHT,
  WIDGET_TYPE_START_AND_DUE_DATE,
  NEW_WORK_ITEM_IID,
  WIDGET_TYPE_MILESTONE,
  WIDGET_TYPE_HIERARCHY,
} from '../constants';
import workItemByIidQuery from './work_item_by_iid.query.graphql';

// eslint-disable-next-line max-params
const updateWidget = (draftData, widgetType, newData, nodePath) => {
  /** set all other values other than when it is undefined including null/0 or empty array as well */
  /** we have to make sure we do not pass values when custom types are introduced */
  if (newData === undefined) return;

  if (draftData.workspace) {
    const widget = findWidget(widgetType, draftData.workspace.workItem);
    set(widget, nodePath, newData);
  }
};

const updateDatesWidget = (draftData, dates) => {
  if (!dates) return;

  const dueDate = dates.dueDate ? toISODateFormat(newDate(dates.dueDate)) : null;
  const startDate = dates.startDate ? toISODateFormat(newDate(dates.startDate)) : null;

  const widget = findWidget(WIDGET_TYPE_START_AND_DUE_DATE, draftData.workspace.workItem);
  Object.assign(widget, {
    dueDate,
    startDate,
    isFixed: dates.isFixed,
    rollUp: dates.rollUp,
    __typename: 'WorkItemWidgetStartAndDueDate',
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
    weight,
    milestone,
    parent,
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
        {
          widgetType: WIDGET_TYPE_WEIGHT,
          newData: weight,
          nodePath: 'weight',
        },
        {
          widgetType: WIDGET_TYPE_MILESTONE,
          newData: milestone,
          nodePath: 'milestone',
        },
        {
          widgetType: WIDGET_TYPE_HIERARCHY,
          newData: parent,
          nodePath: 'parent',
        },
      ];

      widgetUpdates.forEach(({ widgetType, newData, nodePath }) => {
        updateWidget(draftData, widgetType, newData, nodePath);
      });

      updateDatesWidget(draftData, rolledUpDates);

      // We want to allow users to delete a title for an in-progress work item draft
      // as we check for the title being valid when submitting the form
      if (title !== undefined) draftData.workspace.workItem.title = title;

      if (confidential !== undefined) draftData.workspace.workItem.confidential = confidential;
    }),
  );

  const newData = cache.readQuery({ query, variables });

  const autosaveKey = getNewWorkItemAutoSaveKey(fullPath, workItemType);

  const isQueryDataValid = !isEmpty(newData) && newData?.workspace?.workItem;

  const isWorkItemToResolveDiscussion = getParameterByName(
    'merge_request_to_resolve_discussions_of',
  );

  if (isQueryDataValid && autosaveKey && !isWorkItemToResolveDiscussion) {
    updateDraft(autosaveKey, JSON.stringify(newData));
  }
};

export const workItemBulkEdit = (input) => {
  return {
    updatedIssueCount: input.ids.length,
  };
};

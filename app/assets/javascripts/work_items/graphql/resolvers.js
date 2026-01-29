import { set, isEmpty } from 'lodash';
import { produce } from 'immer';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { findWidget } from '~/work_items/list/utils';
import { newDate, toISODateFormat } from '~/lib/utils/datetime_utility';
import { updateDraft } from '~/lib/utils/autosave';
import {
  findCustomFieldsWidget,
  findStartAndDueDateWidget,
  getNewWorkItemAutoSaveKey,
  getNewWorkItemWidgetsAutoSaveKey,
  newWorkItemFullPath,
  getWorkItemWidgets,
} from '../utils';
import {
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_COLOR,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_HEALTH_STATUS,
  WIDGET_TYPE_DESCRIPTION,
  WIDGET_TYPE_CRM_CONTACTS,
  WIDGET_TYPE_ITERATION,
  WIDGET_TYPE_WEIGHT,
  NEW_WORK_ITEM_IID,
  WIDGET_TYPE_MILESTONE,
  WIDGET_TYPE_HIERARCHY,
  WIDGET_TYPE_CUSTOM_FIELDS,
  CUSTOM_FIELDS_TYPE_SINGLE_SELECT,
  CUSTOM_FIELDS_TYPE_MULTI_SELECT,
  CUSTOM_FIELDS_TYPE_TEXT,
  WIDGET_TYPE_STATUS,
} from '../constants';
import workItemByIidQuery from './work_item_by_iid.query.graphql';

// eslint-disable-next-line max-params
const updateWidget = (draftData, widgetType, newData, nodePath) => {
  /** set all other values other than when it is undefined including null/0 or empty array as well */
  /** we have to make sure we do not pass values when custom types are introduced */
  if (newData === undefined) return;

  if (draftData.namespace) {
    const widget = findWidget(widgetType, draftData.namespace.workItem);
    set(widget, nodePath, newData);
  }
};

const updateDatesWidget = (draftData, dates) => {
  if (!dates) return;

  const dueDate = dates.dueDate ? toISODateFormat(newDate(dates.dueDate)) : null;
  const startDate = dates.startDate ? toISODateFormat(newDate(dates.startDate)) : null;

  const widget = findStartAndDueDateWidget(draftData.namespace.workItem);
  Object.assign(widget, {
    dueDate,
    startDate,
    isFixed: dates.isFixed,
    rollUp: dates.rollUp,
    __typename: 'WorkItemWidgetStartAndDueDate',
  });
};

const updateCustomFieldsWidget = (sourceData, draftData, customField) => {
  if (!customField) return;

  const widget = findCustomFieldsWidget(draftData.namespace.workItem);

  if (!widget) return;

  const currentValues =
    sourceData?.namespace?.workItem?.widgets?.find((w) => w.type === WIDGET_TYPE_CUSTOM_FIELDS)
      ?.customFieldValues ?? [];

  const updatedCustomFieldValues = currentValues.map((field) => {
    if (field?.customField?.id === customField.id) {
      if (
        field.customField.fieldType === CUSTOM_FIELDS_TYPE_SINGLE_SELECT ||
        field.customField.fieldType === CUSTOM_FIELDS_TYPE_MULTI_SELECT
      ) {
        return { ...field, selectedOptions: customField.selectedOptions };
      }
      if (field.customField.fieldType === CUSTOM_FIELDS_TYPE_TEXT) {
        return { ...field, value: customField.textValue };
      }
      return { ...field, value: customField.numberValue };
    }
    return field;
  });

  Object.assign(widget, {
    customFieldValues: updatedCustomFieldValues,
    __typename: 'WorkItemWidgetCustomFields',
  });
};

export const updateNewWorkItemCache = (input, cache) => {
  const {
    context,
    relatedItemId,
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
    customField,
    status,
  } = input;

  try {
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
          {
            widgetType: WIDGET_TYPE_STATUS,
            newData: status,
            nodePath: 'status',
          },
        ];

        widgetUpdates.forEach(({ widgetType, newData, nodePath }) => {
          updateWidget(draftData, widgetType, newData, nodePath);
        });

        updateDatesWidget(draftData, rolledUpDates);
        updateCustomFieldsWidget(sourceData, draftData, customField);

        // We want to allow users to delete a title for an in-progress work item draft
        // as we check for the title being valid when submitting the form
        if (title !== undefined) draftData.namespace.workItem.title = title;

        if (confidential !== undefined) draftData.namespace.workItem.confidential = confidential;
      }),
    );

    const newData = cache.readQuery({ query, variables });

    const autosaveKey = getNewWorkItemAutoSaveKey({
      fullPath,
      context,
      workItemType,
      relatedItemId,
    });

    const isQueryDataValid = !isEmpty(newData) && newData?.namespace?.workItem;

    if (isQueryDataValid && autosaveKey) {
      updateDraft(autosaveKey, JSON.stringify(newData));
      updateDraft(
        getNewWorkItemWidgetsAutoSaveKey({ fullPath, context, relatedItemId }),
        JSON.stringify(getWorkItemWidgets(newData)),
      );
    }
  } catch (e) {
    Sentry.captureException(e);
  }
};

export const workItemBulkEdit = (input) => {
  return {
    updatedIssueCount: input.ids.length,
  };
};

// TODO: remove mock data at integration
/* eslint-disable @gitlab/require-i18n-strings */
export const allSavedViews = [
  {
    name: 'AI team 1',
    description: 'Work focusing on chatbot and other AI features',
    subscribed: false,
    private: false,
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/11',
    userPermissions: {
      updateSavedView: true,
    },
  },
  {
    name: 'Backlog 2',
    description: 'Upcoming work and items to be scheduled',
    subscribed: true,
    private: false,
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/2',
    userPermissions: {
      updateSavedView: true,
    },
  },
  {
    name: 'Current sprint 3',
    description: 'The things I am focused on for the sprint',
    subscribed: false,
    private: true,
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/13',
    userPermissions: {
      updateSavedView: false,
    },
  },
  {
    name: 'Daily standup 4',
    description: 'Our daily standup board to review WIP and check status',
    subscribed: false,
    private: false,
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/14',
    userPermissions: {
      updateSavedView: true,
    },
  },
  {
    name: 'Doc site redesign 5',
    description: 'Redesigning the docs site for improved searching',
    subscribed: false,
    private: false,
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/15',
    userPermissions: {
      updateSavedView: true,
    },
  },
  {
    name: 'Engineering workflow 6',
    description: 'Various stages of development ongoing items are in',
    subscribed: false,
    private: false,
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/16',
    userPermissions: {
      updateSavedView: true,
    },
  },
  {
    name: 'FY25 OKRs 7',
    description: 'Objectives and key results for the year',
    subscribed: false,
    private: false,
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/17',
    userPermissions: {
      updateSavedView: true,
    },
  },
  {
    name: 'Daily standup 8',
    description: 'Our daily standup board to review WIP and check status',
    subscribed: false,
    private: false,
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/18',
    userPermissions: {
      updateSavedView: true,
    },
  },
  {
    name: 'Daily standup 9',
    description: 'Our daily standup board to review WIP and check status',
    subscribed: false,
    private: false,
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/19',
    userPermissions: {
      updateSavedView: true,
    },
  },
  {
    name: 'Doc site redesign 10',
    description: 'Redesigning the docs site for improved searching',
    subscribed: false,
    private: false,
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/110',
    userPermissions: {
      updateSavedView: true,
    },
  },
  {
    name: 'Engineering workflow 11',
    description: 'Various stages of development ongoing items are in',
    subscribed: false,
    private: false,
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/111',
    userPermissions: {
      updateSavedView: true,
    },
  },
  {
    name: 'FY25 OKRs 12',
    description: 'Objectives and key results for the year',
    subscribed: false,
    private: false,
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/112',
    userPermissions: {
      updateSavedView: true,
    },
  },
  {
    name: 'Daily standup 13',
    description: 'Our daily standup board to review WIP and check status',
    subscribed: false,
    private: false,
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/113',
    userPermissions: {
      updateSavedView: true,
    },
  },
];

export const allSubscribedSavedViews = [
  {
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/1',
    name: 'AI team',
    description: 'Work focusing on chatbot and other AI features',
    private: true,
    subscribed: true,
    userPermissions: {
      updateSavedView: true,
    },
    __typename: 'WorkItemSavedViewType',
  },
  {
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/2',
    name: 'Backlog',
    description: 'Upcoming work and items to be scheduled',
    private: false,
    subscribed: true,
    userPermissions: {
      updateSavedView: true,
    },
    __typename: 'WorkItemSavedViewType',
  },
  {
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/3',
    name: 'Current sprint',
    description: 'The things I am focused on for the sprint',
    private: true,
    subscribed: true,
    userPermissions: {
      updateSavedView: true,
    },
    __typename: 'WorkItemSavedViewType',
  },
  {
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/4',
    name: 'Daily standup',
    description: 'Our daily standup board to review WIP and check status',
    private: false,
    subscribed: true,
    userPermissions: {
      updateSavedView: true,
    },
    __typename: 'WorkItemSavedViewType',
  },
  {
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/5',
    name: 'Doc site redesign',
    description: 'Redesigning the docs site for improved searching',
    private: false,
    subscribed: true,
    userPermissions: {
      updateSavedView: true,
    },
    __typename: 'WorkItemSavedViewType',
  },
  {
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/6',
    name: 'Engineering workflow',
    description: 'Various stages of development ongoing items are in',
    private: false,
    subscribed: true,
    userPermissions: {
      updateSavedView: true,
    },
    __typename: 'WorkItemSavedViewType',
  },
  {
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/7',
    name: 'FY25 OKRs',
    description: 'Objectives and key results for the year',
    private: false,
    subscribed: true,
    userPermissions: {
      updateSavedView: true,
    },
    __typename: 'WorkItemSavedViewType',
  },
  {
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/8',
    name: 'Daily standup',
    description: 'Our daily standup board to review WIP and check status',
    private: false,
    subscribed: true,
    userPermissions: {
      updateSavedView: true,
    },
    __typename: 'WorkItemSavedViewType',
  },
];

const displaySettings = {
  assignee: true,
  blocked: true,
  blocking: true,
  dates: true,
  health: true,
  labels: true,
  milestone: true,
  popularity: true,
  weight: true,
  comments: true,
  iteration: true,
  status: true,
};

const filters = {
  state: 'opened',
  assigneeUsernames: 'root',
  labelName: 'Broffe',
};

export const singleSavedView = [
  {
    __typename: 'SavedView',
    name: 'Current sprint 3',
    description: 'The things I am focused on for the sprint',
    isSubscribed: false,
    isPrivate: true,
    id: 'gid://gitlab/WorkItems::SavedViews::SavedView/3',
    displaySettings,
    filters,
    sort: 'UPDATED_DESC',
  },
];
/* eslint-enable @gitlab/require-i18n-strings */

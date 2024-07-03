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
  NEW_WORK_ITEM_IID,
} from '../constants';
import groupWorkItemByIidQuery from './group_work_item_by_iid.query.graphql';
import workItemByIidQuery from './work_item_by_iid.query.graphql';

export const updateNewWorkItemCache = (input, cache) => {
  const {
    healthStatus,
    isGroup,
    fullPath,
    workItemType,
    assignees,
    color,
    title,
    description,
    confidential,
    labels,
    rolledUpDates,
  } = input;

  const query = isGroup ? groupWorkItemByIidQuery : workItemByIidQuery;

  const variables = {
    fullPath: newWorkItemFullPath(fullPath, workItemType),
    iid: NEW_WORK_ITEM_IID,
  };

  cache.updateQuery({ query, variables }, (sourceData) =>
    produce(sourceData, (draftData) => {
      if (healthStatus) {
        const healthStatusWidget = findWidget(
          WIDGET_TYPE_HEALTH_STATUS,
          draftData?.workspace?.workItem,
        );

        healthStatusWidget.healthStatus = healthStatus;

        const healthStatusWidgetIndex = draftData.workspace.workItem.widgets.findIndex(
          (widget) => widget.type === WIDGET_TYPE_HEALTH_STATUS,
        );
        draftData.workspace.workItem.widgets[healthStatusWidgetIndex] = healthStatusWidget;
      }

      if (assignees) {
        const assigneesWidget = findWidget(WIDGET_TYPE_ASSIGNEES, draftData?.workspace?.workItem);
        assigneesWidget.assignees.nodes = assignees;

        const assigneesWidgetIndex = draftData.workspace.workItem.widgets.findIndex(
          (widget) => widget.type === WIDGET_TYPE_ASSIGNEES,
        );
        draftData.workspace.workItem.widgets[assigneesWidgetIndex] = assigneesWidget;
      }

      if (labels) {
        const labelsWidget = findWidget(WIDGET_TYPE_LABELS, draftData?.workspace?.workItem);

        labelsWidget.labels.nodes = labels;

        const labelsWidgetIndex = draftData.workspace.workItem.widgets.findIndex(
          (widget) => widget.type === WIDGET_TYPE_LABELS,
        );

        draftData.workspace.workItem.widgets[labelsWidgetIndex] = labelsWidget;
      }

      if (rolledUpDates) {
        let rolledUpDatesWidget = findWidget(
          WIDGET_TYPE_ROLLEDUP_DATES,
          draftData?.workspace?.workItem,
        );

        const dueDate = rolledUpDates.dueDateFixed || null;
        const dueDateFixed = dueDate ? pikadayToString(rolledUpDates.dueDateFixed) : null;
        const startDate = rolledUpDates.startDateFixed || null;
        const startDateFixed = startDate ? pikadayToString(rolledUpDates.startDateFixed) : null;

        rolledUpDatesWidget = {
          type: 'ROLLEDUP_DATES',
          dueDate: dueDateFixed,
          dueDateFixed,
          dueDateIsFixed: rolledUpDates.dueDateIsFixed,
          startDate: startDateFixed,
          startDateFixed,
          startDateIsFixed: rolledUpDates.startDateIsFixed,
          __typename: 'WorkItemWidgetRolledupDates',
        };

        const rolledUpDatesWidgetIndex = draftData.workspace.workItem.widgets.findIndex(
          (widget) => widget.type === WIDGET_TYPE_ROLLEDUP_DATES,
        );

        draftData.workspace.workItem.widgets[rolledUpDatesWidgetIndex] = rolledUpDatesWidget;
      }

      if (color) {
        const colorWidget = findWidget(WIDGET_TYPE_COLOR, draftData?.workspace?.workItem);
        colorWidget.color = color;

        const colorWidgetIndex = draftData.workspace.workItem.widgets.findIndex(
          (widget) => widget.type === WIDGET_TYPE_COLOR,
        );
        draftData.workspace.workItem.widgets[colorWidgetIndex] = colorWidget;
      }

      if (title) {
        draftData.workspace.workItem.title = title;
      }

      if (description) {
        const descriptionWidget = findWidget(
          WIDGET_TYPE_DESCRIPTION,
          draftData?.workspace?.workItem,
        );
        descriptionWidget.description = description;

        const descriptionWidgetIndex = draftData.workspace.workItem.widgets.findIndex(
          (widget) => widget.type === WIDGET_TYPE_DESCRIPTION,
        );
        draftData.workspace.workItem.widgets[descriptionWidgetIndex] = descriptionWidget;
      }

      if (confidential !== undefined) {
        draftData.workspace.workItem.confidential = confidential;
      }
    }),
  );
};

<script>
import { GlModal, GlFormGroup, GlFormSelect, GlAlert } from '@gitlab/ui';
import { differenceBy } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { __, s__, sprintf } from '~/locale';
import { findDesignWidget, findMilestoneWidget, getParentGroupName } from '~/work_items/utils';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

import {
  WIDGET_TYPE_HIERARCHY,
  ALLOWED_CONVERSION_TYPES,
  WORK_ITEM_TYPE_ENUM_EPIC,
  WORK_ITEM_TYPE_NAME_EPIC,
  sprintfWorkItem,
  WORK_ITEM_WIDGETS_NAME_MAP,
  WIDGET_TYPE_DESIGNS,
  WIDGET_TYPE_MILESTONE,
} from '../constants';

import namespaceWorkItemTypesQuery from '../graphql/namespace_work_item_types.query.graphql';
import convertWorkItemMutation from '../graphql/work_item_convert.mutation.graphql';
import getWorkItemDesignListQuery from './design_management/graphql/design_collection.query.graphql';

export default {
  components: {
    GlModal,
    GlFormGroup,
    GlFormSelect,
    GlAlert,
  },
  mixins: [glFeatureFlagMixin()],
  actionCancel: {
    text: __('Cancel'),
  },
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: false,
      default: '',
    },
    workItemType: {
      type: String,
      required: false,
      default: null,
    },
    fullPath: {
      type: String,
      required: true,
    },
    hasChildren: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasParent: {
      type: Boolean,
      required: false,
      default: false,
    },
    widgets: {
      type: Array,
      required: false,
      default: () => [],
    },
    allowedChildTypes: {
      type: Array,
      required: false,
      default: () => [],
    },
    namespaceFullName: {
      type: String,
      required: false,
      default: '',
    },
    allowedWorkItemTypesEE: {
      type: Array,
      required: false,
      default: () => [],
    },
    epicFieldNote: {
      type: String,
      required: false,
      default: '',
    },
    getEpicWidgetDefinitions: {
      type: Function,
      required: false,
      default: () => {},
    },
  },
  data() {
    return {
      selectedWorkItemType: null,
      workItemTypes: [],
      warningMessage: '',
      valueNotPresentWarning: '',
      changeTypeDisabled: true,
      hasDesigns: false,
      typeFieldNote: '',
    };
  },
  apollo: {
    workItemTypes: {
      query: namespaceWorkItemTypesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes || [];
      },
      error(e) {
        this.throwError(e);
      },
    },
    hasDesigns: {
      query: getWorkItemDesignListQuery,
      variables() {
        return {
          id: this.workItemId,
          atVersion: null,
        };
      },
      update(data) {
        return findDesignWidget(data.workItem.widgets)?.designCollection?.designs.nodes?.length > 0;
      },
      error(e) {
        this.throwError(e);
      },
    },
  },
  computed: {
    supportedConversionTypes() {
      return (
        this.workItemTypes
          ?.find((type) => type.name === this.workItemType)
          ?.supportedConversionTypes?.filter((item) => {
            // API is returning Incident, Requirement, Test Case, and Ticket in addition to required work items
            // As these types are not migrated, they are filtered out on the frontend
            // They will be added to the list as they are migrated
            // Discussion: https://gitlab.com/gitlab-org/gitlab/-/issues/498656#note_2263177119
            return ALLOWED_CONVERSION_TYPES.includes(item.name);
          })
          ?.map((item) => ({
            text: item.name,
            value: item.id,
          })) || []
      );
    },
    allowedConversionWorkItemTypes() {
      return [
        {
          text: __('Select type'),
          value: null,
        },
        ...this.supportedConversionTypes,
        ...this.allowedWorkItemTypesEE,
      ];
    },
    workItemsAlphaEnabled() {
      return this.glFeatures.workItemsAlpha;
    },
    isSelectedWorkItemTypeEpic() {
      return this.selectedWorkItemType?.value === WORK_ITEM_TYPE_ENUM_EPIC;
    },
    milestoneWidget() {
      return findMilestoneWidget(this.widgets)?.milestone;
    },
    selectedWorkItemTypeWidgetDefinitions() {
      return this.isSelectedWorkItemTypeEpic
        ? this.getEpicWidgetDefinitions({ workItemTypes: this.workItemTypes })
        : this.getWidgetDefinitions(this.selectedWorkItemType?.text);
    },
    currentWorkItemTypeWidgetDefinitions() {
      return this.getWidgetDefinitions(this.workItemType);
    },
    widgetDifference() {
      return differenceBy(
        this.currentWorkItemTypeWidgetDefinitions,
        this.selectedWorkItemTypeWidgetDefinitions,
        'type',
      );
    },
    widgetsWithExistingDataList() {
      // Filter the widgets based on the presence or absence of data
      const widgetsWithExistingDataList = this.widgetDifference.filter((item) => {
        // Find the widget object
        const widgetObject = this.widgets?.find((widget) => widget.type === item.type);

        // return false if the widget data is not found
        if (!widgetObject) {
          return false;
        }

        // Skip the type and __typename fields
        // It will either have the actual widget object or none
        const fieldName = Object.keys(widgetObject).find(
          (key) => key !== 'type' && key !== '__typename',
        );

        // return false if the field name is undefined
        if (!fieldName) {
          return false;
        }

        // Check if the object has non-empty nodes array or
        // non-empty object
        return widgetObject[fieldName]?.nodes !== undefined
          ? widgetObject[fieldName]?.nodes?.length > 0
          : Boolean(widgetObject[fieldName]);
      });

      if (this.hasDesigns) {
        widgetsWithExistingDataList.push({
          name: WORK_ITEM_WIDGETS_NAME_MAP[WIDGET_TYPE_DESIGNS],
          type: WIDGET_TYPE_DESIGNS,
        });
      }

      return widgetsWithExistingDataList;
    },
    widgetsWithExistingData() {
      return this.widgetsWithExistingDataList.reduce((widgets, item) => {
        // Skip adding milestone to widget difference if upgrading to epic
        if (
          this.workItemsAlphaEnabled &&
          this.isSelectedWorkItemTypeEpic &&
          item.type === WIDGET_TYPE_MILESTONE
        ) {
          return widgets;
        }
        widgets.push({
          ...item,
          name: WORK_ITEM_WIDGETS_NAME_MAP[item.type],
        });
        return widgets;
      }, []);
    },
    noValuePresentWidgets() {
      return this.widgetsWithExistingDataList.reduce((acc, item) => {
        if (
          this.workItemsAlphaEnabled &&
          this.isSelectedWorkItemTypeEpic &&
          this.milestoneWidget?.projectMilestone &&
          item.type === WIDGET_TYPE_MILESTONE
        ) {
          const itemType = WORK_ITEM_WIDGETS_NAME_MAP[item.type];
          const itemText = `${itemType}: ${this.milestoneWidget.title}`;
          acc.push({
            ...item,
            name: itemType,
            title: this.milestoneWidget.title,
            text: itemText,
          });
        }
        return acc;
      }, []);
    },
    hasWidgetDifference() {
      if (this.hasParent || this.hasChildren) {
        return false;
      }
      return this.widgetsWithExistingData.length > 0;
    },
    parentWorkItem() {
      return this.widgets?.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY)?.parent;
    },
    parentWorkItemType() {
      return this.parentWorkItem?.workItemType?.name;
    },
    workItemTypeId() {
      return this.workItemTypes.find((type) => type.name === this.selectedWorkItemType?.text).id;
    },
    selectedWorkItemTypeValue() {
      return this.selectedWorkItemType?.value || null;
    },
    actionPrimary() {
      return {
        text: s__('WorkItem|Change type'),
        attributes: {
          variant: 'confirm',
          disabled: this.changeTypeDisabled,
        },
      };
    },
    isWorkItemTypesQueryLoading() {
      return this.$apollo.queries.workItemTypes.loading;
    },
  },
  methods: {
    changeType() {
      if (this.isSelectedWorkItemTypeEpic) {
        this.$emit('promoteToEpic');
      } else {
        this.convertType();
      }
    },
    async convertType() {
      try {
        const {
          data: {
            workItemConvert: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: convertWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              workItemTypeId: this.workItemTypeId,
            },
          },
        });
        if (errors?.length > 0) {
          this.throwError(errors[0]);
          return;
        }
        this.$toast.show(s__('WorkItem|Type changed.'));
        this.$emit('workItemTypeChanged');
        this.hide();
      } catch (error) {
        this.throwError(error.message);
        Sentry.captureException(error);
      }
    },
    getWidgetDefinitions(type) {
      if (!type) {
        return [];
      }
      return this.workItemTypes.find((widget) => widget.name === type)?.widgetDefinitions;
    },
    updateWorkItemType(value) {
      this.typeFieldNote = '';

      if (!value) {
        this.resetModal();
        return;
      }

      this.selectedWorkItemType = this.allowedConversionWorkItemTypes.find(
        (item) => item.value === value,
      );

      if (value === WORK_ITEM_TYPE_ENUM_EPIC) {
        this.typeFieldNote = this.epicFieldNote;
      }
      this.validateWorkItemType();
    },
    validateWorkItemType() {
      this.changeTypeDisabled = false;
      this.warningMessage = '';
      this.valueNotPresentWarning = '';

      if (this.hasParent) {
        this.warningMessage = sprintfWorkItem(
          s__(
            'WorkItem|Parent item type %{parentWorkItemType} is not supported on %{workItemType}. Remove the parent item to change type.',
          ),
          this.isSelectedWorkItemTypeEpic
            ? WORK_ITEM_TYPE_NAME_EPIC
            : this.selectedWorkItemType.text,
          this.parentWorkItemType,
        );

        this.changeTypeDisabled = true;
        return;
      }

      if (this.hasChildren) {
        this.warningMessage = sprintf(
          s__(
            'WorkItem|%{workItemType} does not support the %{childItemType} child item types. Remove child items to change type.',
          ),
          {
            workItemType: capitalizeFirstCharacter(
              this.isSelectedWorkItemTypeEpic
                ? WORK_ITEM_TYPE_NAME_EPIC.toLocaleLowerCase()
                : this.selectedWorkItemType.text.toLocaleLowerCase(),
            ),
            childItemType: this.allowedChildTypes?.[0]?.name?.toLocaleLowerCase(),
          },
        );

        this.changeTypeDisabled = true;
        return;
      }

      if (this.noValuePresentWidgets.length) {
        this.valueNotPresentWarning = sprintf(
          s__('WorkItem|Some values are not present in %{groupName} and will be removed.'),
          {
            groupName: getParentGroupName(this.namespaceFullName),
          },
        );
      }

      // Compare the widget definitions of both types
      if (this.hasWidgetDifference) {
        this.warningMessage = sprintfWorkItem(
          s__(
            'WorkItem|Some fields are not present in %{workItemType}. If you change type now, this information will be lost.',
          ),
          this.isSelectedWorkItemTypeEpic
            ? WORK_ITEM_TYPE_NAME_EPIC
            : this.selectedWorkItemType.text,
        );
      }
    },
    throwError(message) {
      this.$emit('error', message);
    },
    show() {
      this.resetModal();
      this.$refs.modal.show();
    },
    hide() {
      this.resetModal();
      this.$refs.modal.hide();
    },
    resetModal() {
      this.warningMessage = '';
      this.valueNotPresentWarning = '';
      this.selectedWorkItemType = null;
      this.changeTypeDisabled = true;
      this.typeFieldNote = '';
    },
  },
};
</script>

<template>
  <gl-modal
    v-if="workItemId"
    ref="modal"
    modal-id="work-item-change-type"
    :title="s__('WorkItem|Change type')"
    size="sm"
    :action-primary="actionPrimary"
    :action-cancel="$options.actionCancel"
    @primary="changeType"
    @canceled="hide"
  >
    <div class="gl-mb-4">
      {{ s__('WorkItem|Select which type you would like to change this item to.') }}
    </div>
    <gl-form-group :label="__('Type')" label-for="work-item-type-select">
      <gl-form-select
        id="work-item-type-select"
        class="gl-mb-2"
        data-testid="work-item-change-type-select"
        :value="selectedWorkItemTypeValue"
        width="md"
        :options="allowedConversionWorkItemTypes"
        @change="updateWorkItemType"
      />
      <p v-if="typeFieldNote" class="gl-text-subtle">{{ typeFieldNote }}</p>
    </gl-form-group>
    <gl-alert
      v-if="warningMessage && !isWorkItemTypesQueryLoading"
      data-testid="change-type-warning-message"
      variant="warning"
      :dismissible="false"
    >
      {{ warningMessage }}
      <ul v-if="hasWidgetDifference" class="gl-mb-0">
        <li v-for="widget in widgetsWithExistingData" :key="widget.type">
          {{ widget.name }}
        </li>
      </ul>
    </gl-alert>
    <gl-alert
      v-if="valueNotPresentWarning && !isWorkItemTypesQueryLoading"
      data-testid="change-type-no-value-present-message"
      class="gl-mt-3"
      variant="warning"
      :dismissible="false"
    >
      {{ valueNotPresentWarning }}
      <ul v-if="noValuePresentWidgets.length" class="gl-mb-0">
        <li v-for="widget in noValuePresentWidgets" :key="widget.type">
          {{ widget.text }}
        </li>
      </ul>
    </gl-alert>
  </gl-modal>
</template>

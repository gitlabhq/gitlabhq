<script>
import { GlModal, GlFormGroup, GlFormSelect, GlAlert } from '@gitlab/ui';
import { differenceBy } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { __, s__, sprintf } from '~/locale';
import { findDesignWidget } from '~/work_items/utils';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

import {
  WIDGET_TYPE_HIERARCHY,
  ALLOWED_CONVERSION_TYPES,
  WORK_ITEM_TYPE_ENUM_EPIC,
  WORK_ITEM_TYPE_VALUE_EPIC,
  sprintfWorkItem,
  I18N_WORK_ITEM_CHANGE_TYPE_PARENT_ERROR,
  I18N_WORK_ITEM_CHANGE_TYPE_CHILD_ERROR,
  I18N_WORK_ITEM_CHANGE_TYPE_MISSING_FIELDS_ERROR,
  WORK_ITEM_WIDGETS_NAME_MAP,
  WIDGET_TYPE_DESIGNS,
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
    selectedWorkItemTypeWidgetDefinitions() {
      return this.selectedWorkItemType?.value === WORK_ITEM_TYPE_ENUM_EPIC
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
    widgetsWithExistingData() {
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

      return widgetsWithExistingDataList.map((item) => ({
        ...item,
        name: WORK_ITEM_WIDGETS_NAME_MAP[item.type],
      }));
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
      if (this.selectedWorkItemType.value === WORK_ITEM_TYPE_ENUM_EPIC) {
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

      if (this.hasParent) {
        this.warningMessage = sprintfWorkItem(
          I18N_WORK_ITEM_CHANGE_TYPE_PARENT_ERROR,
          this.selectedWorkItemType.value === WORK_ITEM_TYPE_ENUM_EPIC
            ? WORK_ITEM_TYPE_VALUE_EPIC
            : this.selectedWorkItemType.text,
          this.parentWorkItemType,
        );

        this.changeTypeDisabled = true;
        return;
      }

      if (this.hasChildren) {
        this.warningMessage = sprintf(I18N_WORK_ITEM_CHANGE_TYPE_CHILD_ERROR, {
          workItemType: capitalizeFirstCharacter(
            this.selectedWorkItemType.value === WORK_ITEM_TYPE_ENUM_EPIC
              ? WORK_ITEM_TYPE_VALUE_EPIC.toLocaleLowerCase()
              : this.selectedWorkItemType.text.toLocaleLowerCase(),
          ),
          childItemType: this.allowedChildTypes?.[0]?.name?.toLocaleLowerCase(),
        });

        this.changeTypeDisabled = true;
        return;
      }

      // Compare the widget definitions of both types
      if (this.hasWidgetDifference) {
        this.warningMessage = sprintfWorkItem(
          I18N_WORK_ITEM_CHANGE_TYPE_MISSING_FIELDS_ERROR,
          this.selectedWorkItemType.value === WORK_ITEM_TYPE_ENUM_EPIC
            ? WORK_ITEM_TYPE_VALUE_EPIC
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
  </gl-modal>
</template>

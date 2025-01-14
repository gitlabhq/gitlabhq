<script>
import { GlModal, GlFormGroup, GlFormSelect, GlAlert } from '@gitlab/ui';
import { differenceBy } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __, s__, sprintf } from '~/locale';
import { findDesignWidget } from '~/work_items/utils';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

import {
  WIDGET_TYPE_HIERARCHY,
  WORK_ITEMS_TYPE_MAP,
  WORK_ITEM_ALLOWED_CHANGE_TYPE_MAP,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
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
  mixins: [glFeatureFlagMixin()],
  inject: ['hasOkrsFeature'],
  props: {
    workItemId: {
      type: String,
      required: true,
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
  },
  data() {
    return {
      selectedWorkItemType: null,
      workItemTypes: [],
      warningMessage: '',
      errorMessage: '',
      changeTypeDisabled: true,
      hasDesigns: false,
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
        return data.workspace?.workItemTypes?.nodes;
      },
      error(e) {
        this.showErrorMessage(e);
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
      skip() {
        return !this.workItemId;
      },
      error(e) {
        this.showErrorMessage(e);
      },
    },
  },
  computed: {
    allowedConversionWorkItemTypes() {
      // The logic will be simplified once we implement
      // https://gitlab.com/gitlab-org/gitlab/-/issues/498656
      return [
        { text: __('Select type'), value: null },
        ...Object.entries(WORK_ITEMS_TYPE_MAP)
          .map(([key, value]) => ({
            text: value.value,
            value: key,
          }))
          .filter((item) => {
            if (item.text === this.workItemType) {
              return false;
            }
            // Keeping this separate for readability
            if (
              item.value === WORK_ITEM_TYPE_ENUM_OBJECTIVE ||
              item.value === WORK_ITEM_TYPE_ENUM_KEY_RESULT
            ) {
              return this.isOkrsEnabled;
            }
            return WORK_ITEM_ALLOWED_CHANGE_TYPE_MAP.includes(item.value);
          }),
      ];
    },
    isOkrsEnabled() {
      return this.hasOkrsFeature && this.glFeatures.okrsMvc;
    },
    selectedWorkItemTypeWidgetDefinitions() {
      return this.getWidgetDefinitions(this.selectedWorkItemType?.text);
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
      return this.widgetsWithExistingData.length > 0;
    },
    parentWorkItem() {
      return this.widgets?.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY)?.parent;
    },
    parentWorkItemType() {
      return this.parentWorkItem?.workItemType?.name;
    },
    workItemTypeId() {
      return this.workItemTypes.find((type) => type.name === this.selectedWorkItemType.text).id;
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
  },
  methods: {
    async changeType() {
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
        if (errors.length > 0) {
          this.showErrorMessage(errors[0]);
          return;
        }
        this.$toast.show(s__('WorkItem|Type changed.'));
        this.$emit('workItemTypeChanged');
        this.hide();
      } catch (error) {
        this.showErrorMessage(error);
        Sentry.captureException(error);
      }
    },
    getWidgetDefinitions(type) {
      if (!type) {
        return [];
      }
      return this.workItemTypes.find((widget) => widget.name === type)?.widgetDefinitions;
    },
    validateWorkItemType(value) {
      this.changeTypeDisabled = false;
      this.warningMessage = '';
      if (!value) {
        this.resetModal();
        return;
      }

      this.selectedWorkItemType = this.allowedConversionWorkItemTypes.find(
        (item) => item.value === value,
      );

      if (this.hasParent) {
        this.showWarningMessage(
          sprintfWorkItem(
            I18N_WORK_ITEM_CHANGE_TYPE_PARENT_ERROR,
            this.selectedWorkItemType.text,
            this.parentWorkItemType,
          ),
        );
        this.changeTypeDisabled = true;
        return;
      }

      if (this.hasChildren) {
        const msg = sprintf(I18N_WORK_ITEM_CHANGE_TYPE_CHILD_ERROR, {
          workItemType: capitalizeFirstCharacter(
            this.selectedWorkItemType.text.toLocaleLowerCase(),
          ),
          childItemType: this.allowedChildTypes?.[0]?.name?.toLocaleLowerCase(),
        });

        this.showWarningMessage(msg);
        this.changeTypeDisabled = true;
        return;
      }

      // Compare the widget definitions of both types
      if (this.hasWidgetDifference) {
        this.warningMessage = sprintfWorkItem(
          I18N_WORK_ITEM_CHANGE_TYPE_MISSING_FIELDS_ERROR,
          this.selectedWorkItemType.text,
        );
      }
    },
    showWarningMessage(message) {
      this.warningMessage = message;
    },
    showErrorMessage(message) {
      this.errorMessage = message;
    },
    show() {
      this.resetModal();
      this.changeTypeDisabled = true;
      this.$refs.modal.show();
    },
    hide() {
      this.resetModal();
      this.$refs.modal.hide();
    },
    resetModal() {
      this.warningMessage = '';
      this.errorMessage = '';
      this.showDifferenceMessage = false;
      this.selectedWorkItemType = null;
      this.changeTypeDisabled = false;
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
    <gl-alert
      v-if="errorMessage"
      data-testid="change-type-error-message"
      class="gl-mb-3"
      variant="danger"
      @dismiss="errorMessage = undefined"
    >
      {{ errorMessage }}
    </gl-alert>
    <div class="gl-mb-4">
      {{ s__('WorkItem|Select which type you would like to change this item to.') }}
    </div>
    <gl-form-group :label="__('Type')" label-for="work-item-type-select">
      <gl-form-select
        id="work-item-type-select"
        data-testid="work-item-change-type-select"
        :value="selectedWorkItemTypeValue"
        width="md"
        :options="allowedConversionWorkItemTypes"
        @change="validateWorkItemType"
      />
    </gl-form-group>
    <gl-alert
      v-if="warningMessage"
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

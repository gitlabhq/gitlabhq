<script>
import { GlToggle } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import {
  FORM_TYPES,
  WIDGET_TYPE_HIERARCHY,
  WORK_ITEMS_TREE_TEXT_MAP,
  WORK_ITEM_TYPE_VALUE_MAP,
  WORK_ITEMS_TYPE_MAP,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  I18N_WORK_ITEM_SHOW_LABELS,
  CHILD_ITEMS_ANCHOR,
} from '../../constants';
import { findHierarchyWidgetDefinition } from '../../utils';
import getAllowedWorkItemChildTypes from '../../graphql/work_item_allowed_children.query.graphql';
import WidgetWrapper from '../widget_wrapper.vue';
import WorkItemActionsSplitButton from './work_item_actions_split_button.vue';
import WorkItemLinksForm from './work_item_links_form.vue';
import WorkItemChildrenWrapper from './work_item_children_wrapper.vue';

export default {
  FORM_TYPES,
  WORK_ITEMS_TREE_TEXT_MAP,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  components: {
    WorkItemActionsSplitButton,
    WidgetWrapper,
    WorkItemLinksForm,
    WorkItemChildrenWrapper,
    GlToggle,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    parentWorkItemType: {
      type: String,
      required: false,
      default: '',
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
    confidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    children: {
      type: Array,
      required: false,
      default: () => [],
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      error: undefined,
      isShownAddForm: false,
      formType: null,
      childType: null,
      widgetName: CHILD_ITEMS_ANCHOR,
      showLabels: true,
      allowedChildrenTypes: [],
    };
  },
  apollo: {
    allowedChildrenTypes: {
      query: getAllowedWorkItemChildTypes,
      variables() {
        return {
          id: this.workItemId,
        };
      },
      update(data) {
        return findHierarchyWidgetDefinition(data.workItem.workItemType.widgetDefinitions)
          .allowedChildTypes.nodes;
      },
    },
  },
  computed: {
    childrenIds() {
      return this.children.map((c) => c.id);
    },
    hasIndirectChildren() {
      return this.children
        .map(
          (child) => child.widgets?.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY) || {},
        )
        .some((hierarchy) => hierarchy.hasChildren);
    },
    addItemsActions() {
      const reorderedChildTypes = this.allowedChildrenTypes
        .slice()
        .sort((a, b) => a.id.localeCompare(b.id));
      return reorderedChildTypes.map((type) => {
        const enumType = WORK_ITEM_TYPE_VALUE_MAP[type.name];
        return {
          name: WORK_ITEMS_TYPE_MAP[enumType].name,
          items: this.genericActionItems(type.name).map((item) => ({
            text: item.title,
            action: item.action,
          })),
        };
      });
    },
  },
  methods: {
    genericActionItems(workItem) {
      const enumType = WORK_ITEM_TYPE_VALUE_MAP[workItem];
      const workItemName = WORK_ITEMS_TYPE_MAP[enumType].name.toLowerCase();
      return [
        {
          title: sprintf(s__('WorkItem|New %{workItemName}'), { workItemName }),
          action: () => this.showAddForm(FORM_TYPES.create, enumType),
        },
        {
          title: sprintf(s__('WorkItem|Existing %{workItemName}'), { workItemName }),
          action: () => this.showAddForm(FORM_TYPES.add, enumType),
        },
      ];
    },
    showAddForm(formType, childType) {
      this.$refs.wrapper.show();
      this.isShownAddForm = true;
      this.formType = formType;
      this.childType = childType;
      this.$nextTick(() => {
        this.$refs.wiLinksForm.$refs.wiTitleInput?.$el.focus();
      });
    },
    hideAddForm() {
      this.isShownAddForm = false;
    },
    showModal({ event, child }) {
      this.$emit('show-modal', { event, modalWorkItem: child });
    },
  },
  i18n: {
    showLabelsLabel: I18N_WORK_ITEM_SHOW_LABELS,
  },
};
</script>

<template>
  <widget-wrapper
    ref="wrapper"
    :widget-name="widgetName"
    :error="error"
    data-testid="work-item-tree"
    @dismissAlert="error = undefined"
  >
    <template #header>
      {{ $options.WORK_ITEMS_TREE_TEXT_MAP[workItemType].title }}
    </template>
    <template #header-right>
      <gl-toggle
        class="gl-mr-4"
        :value="showLabels"
        :label="$options.i18n.showLabelsLabel"
        label-position="left"
        label-id="relationship-toggle-labels"
        @change="showLabels = $event"
      />
      <work-item-actions-split-button v-if="canUpdate" :actions="addItemsActions" />
    </template>
    <template #body>
      <div class="gl-new-card-content">
        <div v-if="!isShownAddForm && children.length === 0" data-testid="tree-empty">
          <p class="gl-new-card-empty">
            {{ $options.WORK_ITEMS_TREE_TEXT_MAP[workItemType].empty }}
          </p>
        </div>
        <work-item-links-form
          v-if="isShownAddForm"
          ref="wiLinksForm"
          data-testid="add-tree-form"
          :full-path="fullPath"
          :issuable-gid="workItemId"
          :work-item-iid="workItemIid"
          :form-type="formType"
          :parent-work-item-type="parentWorkItemType"
          :children-type="childType"
          :children-ids="childrenIds"
          :parent-confidential="confidential"
          @cancel="hideAddForm"
          @addChild="$emit('addChild')"
        />
        <work-item-children-wrapper
          :children="children"
          :can-update="canUpdate"
          :full-path="fullPath"
          :work-item-id="workItemId"
          :work-item-iid="workItemIid"
          :work-item-type="workItemType"
          :show-labels="showLabels"
          @error="error = $event"
          @show-modal="showModal"
        />
      </div>
    </template>
  </widget-wrapper>
</template>

<script>
import {
  FORM_TYPES,
  WIDGET_TYPE_HIERARCHY,
  WORK_ITEMS_TREE_TEXT_MAP,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
} from '../../constants';
import workItemByIidQuery from '../../graphql/work_item_by_iid.query.graphql';
import WidgetWrapper from '../widget_wrapper.vue';
import OkrActionsSplitButton from './okr_actions_split_button.vue';
import WorkItemLinksForm from './work_item_links_form.vue';
import WorkItemChildrenWrapper from './work_item_children_wrapper.vue';

export default {
  FORM_TYPES,
  WORK_ITEMS_TREE_TEXT_MAP,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  components: {
    OkrActionsSplitButton,
    WidgetWrapper,
    WorkItemLinksForm,
    WorkItemChildrenWrapper,
  },
  props: {
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
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isShownAddForm: false,
      formType: null,
      childType: null,
      prefetchedWorkItem: null,
    };
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
  },
  methods: {
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
    addWorkItemQuery(iid) {
      if (!iid) {
        return;
      }

      this.$apollo.addSmartQuery('prefetchedWorkItem', {
        query: workItemByIidQuery,
        variables: {
          fullPath: this.projectPath,
          iid,
        },
        update(data) {
          return data.workspace.workItems.nodes[0];
        },
        context: {
          isSingleRequest: true,
        },
      });
    },
  },
};
</script>

<template>
  <widget-wrapper ref="wrapper" data-testid="work-item-tree">
    <template #header>
      {{ $options.WORK_ITEMS_TREE_TEXT_MAP[workItemType].title }}
    </template>
    <template #header-right>
      <okr-actions-split-button
        v-if="canUpdate"
        @showCreateObjectiveForm="
          showAddForm($options.FORM_TYPES.create, $options.WORK_ITEM_TYPE_ENUM_OBJECTIVE)
        "
        @showAddObjectiveForm="
          showAddForm($options.FORM_TYPES.add, $options.WORK_ITEM_TYPE_ENUM_OBJECTIVE)
        "
        @showCreateKeyResultForm="
          showAddForm($options.FORM_TYPES.create, $options.WORK_ITEM_TYPE_ENUM_KEY_RESULT)
        "
        @showAddKeyResultForm="
          showAddForm($options.FORM_TYPES.add, $options.WORK_ITEM_TYPE_ENUM_KEY_RESULT)
        "
      />
    </template>
    <template #body>
      <div v-if="!isShownAddForm && children.length === 0" data-testid="tree-empty">
        <p class="gl-mb-0 gl-py-2 gl-ml-3 gl-text-gray-500">
          {{ $options.WORK_ITEMS_TREE_TEXT_MAP[workItemType].empty }}
        </p>
      </div>
      <work-item-links-form
        v-if="isShownAddForm"
        ref="wiLinksForm"
        data-testid="add-tree-form"
        :issuable-gid="workItemId"
        :form-type="formType"
        :parent-work-item-type="parentWorkItemType"
        :children-type="childType"
        :children-ids="childrenIds"
        :parent-confidential="confidential"
        @addWorkItemChild="$emit('addWorkItemChild', $event)"
        @cancel="hideAddForm"
      />
      <work-item-children-wrapper
        :children="children"
        :project-path="projectPath"
        :can-update="canUpdate"
        :work-item-id="workItemId"
        :work-item-iid="workItemIid"
        :work-item-type="workItemType"
        fetch-by-iid
        @removeChild="$emit('removeChild', $event)"
        @show-modal="showModal"
      />
    </template>
  </widget-wrapper>
</template>

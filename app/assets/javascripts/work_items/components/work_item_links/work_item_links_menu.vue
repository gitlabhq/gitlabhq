<script>
import { GlIcon, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { produce } from 'immer';
import { s__ } from '~/locale';
import changeWorkItemParentMutation from '../../graphql/change_work_item_parent_link.mutation.graphql';
import getWorkItemLinksQuery from '../../graphql/work_item_links.query.graphql';
import { WIDGET_TYPE_HIERARCHY } from '../../constants';

export default {
  components: {
    GlDropdownItem,
    GlDropdown,
    GlIcon,
  },
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    parentWorkItemId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      activeToast: null,
    };
  },
  methods: {
    toggleChildFromCache(data, store) {
      const sourceData = store.readQuery({
        query: getWorkItemLinksQuery,
        variables: { id: this.parentWorkItemId },
      });

      const newData = produce(sourceData, (draftState) => {
        const widgetHierarchy = draftState.workItem.widgets.find(
          (widget) => widget.type === WIDGET_TYPE_HIERARCHY,
        );

        const index = widgetHierarchy.children.nodes.findIndex(
          (child) => child.id === this.workItemId,
        );

        if (index >= 0) {
          widgetHierarchy.children.nodes.splice(index, 1);
        } else {
          widgetHierarchy.children.nodes.push(data.workItemUpdate.workItem);
        }
      });

      store.writeQuery({
        query: getWorkItemLinksQuery,
        variables: { id: this.parentWorkItemId },
        data: newData,
      });
    },
    async addChild(data) {
      const { data: resp } = await this.$apollo.mutate({
        mutation: changeWorkItemParentMutation,
        variables: { id: this.workItemId, parentId: this.parentWorkItemId },
        update: this.toggleChildFromCache.bind(this, data),
      });

      if (resp.workItemUpdate.errors.length === 0) {
        this.activeToast?.hide();
      }
    },
    async removeChild() {
      const { data } = await this.$apollo.mutate({
        mutation: changeWorkItemParentMutation,
        variables: { id: this.workItemId, parentId: null },
        update: this.toggleChildFromCache.bind(this, null),
      });

      if (data.workItemUpdate.errors.length === 0) {
        this.activeToast = this.$toast.show(s__('WorkItem|Child removed'), {
          action: {
            text: s__('WorkItem|Undo'),
            onClick: this.addChild.bind(this, data),
          },
        });
      }
    },
  },
};
</script>

<template>
  <span class="gl-ml-2">
    <gl-dropdown category="tertiary" toggle-class="btn-icon" :right="true">
      <template #button-content>
        <gl-icon name="ellipsis_v" :size="14" />
      </template>
      <gl-dropdown-item @click="removeChild">
        {{ s__('WorkItem|Remove') }}
      </gl-dropdown-item>
    </gl-dropdown>
  </span>
</template>

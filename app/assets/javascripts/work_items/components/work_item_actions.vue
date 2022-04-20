<script>
import { GlDropdown, GlDropdownItem, GlModal, GlModalDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import deleteWorkItemMutation from '../graphql/delete_work_item.mutation.graphql';

export default {
  i18n: {
    deleteWorkItem: s__('WorkItem|Delete work item'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['workItemDeleted', 'error'],
  methods: {
    deleteWorkItem() {
      this.$apollo
        .mutate({
          mutation: deleteWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
            },
          },
        })
        .then(({ data: { workItemDelete, errors } }) => {
          if (errors?.length) {
            throw new Error(errors[0].message);
          }

          if (workItemDelete?.errors.length) {
            throw new Error(workItemDelete.errors[0]);
          }

          this.$emit('workItemDeleted');
        })
        .catch((e) => {
          this.$emit(
            'error',
            e.message ||
              s__('WorkItem|Something went wrong when deleting the work item. Please try again.'),
          );
        });
    },
  },
};
</script>

<template>
  <div v-if="canUpdate">
    <gl-dropdown
      icon="ellipsis_v"
      text-sr-only
      :text="__('More actions')"
      category="tertiary"
      no-caret
      right
    >
      <gl-dropdown-item v-gl-modal="'work-item-confirm-delete'">{{
        $options.i18n.deleteWorkItem
      }}</gl-dropdown-item>
    </gl-dropdown>
    <gl-modal
      modal-id="work-item-confirm-delete"
      :title="$options.i18n.deleteWorkItem"
      :ok-title="$options.i18n.deleteWorkItem"
      ok-variant="danger"
      @ok="deleteWorkItem"
    >
      {{
        s__(
          'WorkItem|Are you sure you want to delete the work item? This action cannot be reversed.',
        )
      }}
    </gl-modal>
  </div>
</template>

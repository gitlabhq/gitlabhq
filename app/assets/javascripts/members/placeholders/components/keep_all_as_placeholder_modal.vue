<script>
import { GlModal } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { createAlert } from '~/alert';
import { getFirstPropertyValue } from '~/lib/utils/common_utils';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import importSourceUsersQuery from '../graphql/queries/import_source_users.query.graphql';
import importSourceUserKeepAllAsPlaceholderMutation from '../graphql/mutations/keep_all_as_placeholder.mutation.graphql';

export default {
  components: {
    GlModal,
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    groupId: {
      type: Number,
      required: true,
    },
  },
  methods: {
    keepAllAsPlaceholder() {
      this.$apollo
        .mutate({
          mutation: importSourceUserKeepAllAsPlaceholderMutation,
          variables: {
            namespaceId: convertToGraphQLId(TYPENAME_GROUP, this.groupId),
          },
          refetchQueries: [importSourceUsersQuery],
        })
        .then(({ data }) => {
          const { errors } = getFirstPropertyValue(data);
          if (errors?.length) {
            createAlert({ message: errors.join() });
          } else {
            const { updatedImportSourceUserCount } = getFirstPropertyValue(data);
            this.$emit('confirm', updatedImportSourceUserCount);
          }
        })
        .catch(() => {
          createAlert({
            message: s__('UserMapping|Keeping all as placeholders could not be done.'),
          });
        })
        .finally(() => {
          this.closeModal();
        });
    },
    closeModal() {
      this.$refs.modal.hide();
    },
  },
  primaryAction: {
    text: __('Confirm'),
  },
  cancelAction: {
    text: __('Cancel'),
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    :title="s__('UserMapping|Keep all as placeholders?')"
    :action-primary="$options.primaryAction"
    :action-cancel="$options.cancelAction"
    @primary="keepAllAsPlaceholder"
  >
    {{
      s__(
        'UserMapping|If you keep all as placeholders, you cannot reassign their contributions to users at a later time. Ensure all required reassignments are completed before you keep all as placeholders.',
      )
    }}
  </gl-modal>
</template>

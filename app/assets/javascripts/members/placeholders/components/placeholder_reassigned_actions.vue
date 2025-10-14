<script>
import { GlAvatarLabeled, GlButton } from '@gitlab/ui';
import { getFirstPropertyValue } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import {
  PLACEHOLDER_STATUS_COMPLETED,
  PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER,
} from '~/import_entities/import_groups/constants';
import importSourceUserUndoKeepAsPlaceholderMutation from '../graphql/mutations/undo_keep_as_placeholder.mutation.graphql';

export default {
  name: 'PlaceholderReassignedActions',
  components: {
    GlAvatarLabeled,
    GlButton,
  },
  props: {
    sourceUser: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },

  data() {
    return {
      isUndoLoading: false,
    };
  },

  computed: {
    statusIsKeepAsPlaceholder() {
      return this.sourceUser.status === PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER;
    },
  },

  methods: {
    reassignedUser() {
      if (this.sourceUser.status === PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER) {
        return this.sourceUser.placeholderUser;
      }
      if (this.sourceUser.status === PLACEHOLDER_STATUS_COMPLETED) {
        return this.sourceUser.reassignToUser;
      }

      return {};
    },

    onUndo() {
      this.isUndoLoading = true;
      this.$apollo
        .mutate({
          mutation: importSourceUserUndoKeepAsPlaceholderMutation,
          variables: {
            id: this.sourceUser.id,
          },
        })
        .then(({ data }) => {
          const { errors } = getFirstPropertyValue(data);
          if (errors?.length) {
            createAlert({ message: errors.join() });
          }
        })
        .catch(() => {
          createAlert({
            message: s__('UserMappingKeepAsPlaceholder|Status could not be changed.'),
          });
        })
        .finally(() => {
          this.isUndoLoading = false;
        });
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-wrap gl-items-start gl-gap-3" data-testid="placeholder-reassigned">
    <gl-avatar-labeled
      :size="32"
      :src="reassignedUser().avatarUrl"
      :label="reassignedUser().name"
      :sub-label="`@${reassignedUser().username}`"
    />

    <template v-if="statusIsKeepAsPlaceholder">
      <gl-button :loading="isUndoLoading" data-testid="undo-button" @click="onUndo">{{
        __('Undo')
      }}</gl-button>
    </template>
  </div>
</template>

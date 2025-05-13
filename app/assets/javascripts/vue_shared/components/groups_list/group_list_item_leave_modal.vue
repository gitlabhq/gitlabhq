<script>
import { GlModal } from '@gitlab/ui';
import { sprintf } from '@gitlab/ui/dist/utils/i18n';
import { renderLeaveSuccessToast } from '~/vue_shared/components/groups_list/utils';
import { createAlert } from '~/alert';
import { s__, __ } from '~/locale';
import { deleteGroupMember } from '~/api/groups_api';

export default {
  name: 'GroupListItemLeaveModal',
  components: {
    GlModal,
  },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
    modalId: {
      type: String,
      required: true,
    },
    group: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  modal: {
    actionCancel: { text: __('Cancel') },
  },
  computed: {
    title() {
      return sprintf(s__('GroupsTree|Are you sure you want to leave "%{fullName}"?'), {
        fullName: this.group.fullName,
      });
    },
    actionPrimary() {
      return {
        text: s__('GroupsTree|Leave group'),
        attributes: {
          variant: 'danger',
          loading: this.isLoading,
        },
      };
    },
  },
  methods: {
    async handlePrimary() {
      this.isLoading = true;

      try {
        await deleteGroupMember(this.group.id, gon.current_user_id);
        this.$emit('success');
        renderLeaveSuccessToast(this.group);
      } catch (error) {
        createAlert({
          message: s__(
            'GroupsTree|An error occurred while leaving the group. Please refresh the page to try again.',
          ),
          error,
          captureError: true,
        });
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <gl-modal
    v-bind="$options.modal"
    :modal-id="modalId"
    :visible="visible"
    :title="title"
    :action-primary="actionPrimary"
    @primary.prevent="handlePrimary"
    @change="$emit('change')"
  >
    <p>{{ s__('GroupsTree|When you leave this group:') }}</p>
    <ul>
      <li>{{ s__('GroupsTree|You lose access to all projects within this group') }}</li>
      <li>
        {{
          s__(
            'GroupsTree|Your assigned issues and merge requests remain, but you cannot view or modify them',
          )
        }}
      </li>
      <li>{{ s__('GroupsTree|You need an invitation to rejoin') }}</li>
    </ul>
  </gl-modal>
</template>

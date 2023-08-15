<script>
import { GlModal, GlForm, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import csrf from '~/lib/utils/csrf';
import { __, s__, sprintf } from '~/locale';
import UserDeletionObstaclesList from '~/vue_shared/components/user_deletion_obstacles/user_deletion_obstacles_list.vue';
import { parseUserDeletionObstacles } from '~/vue_shared/components/user_deletion_obstacles/utils';
import {
  LEAVE_MODAL_ID,
  MEMBER_MODEL_TYPE_GROUP_MEMBER,
  MEMBER_MODEL_TYPE_PROJECT_MEMBER,
} from '../../constants';

export default {
  name: 'LeaveModal',
  actionCancel: {
    text: __('Cancel'),
  },
  csrf,
  modalId: LEAVE_MODAL_ID,
  i18n: {
    title: s__('Members|Leave "%{source}"'),
    body: s__('Members|Are you sure you want to leave "%{source}"?'),
    preventedTitle: s__('Members|Cannot leave "%{source}"'),
    preventedBodyProjectMemberModelType: s__(
      'Members|You cannot remove yourself from a personal project.',
    ),
    preventedBodyGroupMemberModelType: s__(
      'Members|A group must have at least one owner. To leave this group, assign a new owner.',
    ),
  },
  components: { GlModal, GlForm, GlSprintf, UserDeletionObstaclesList },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['namespace'],
  props: {
    member: {
      type: Object,
      required: true,
    },
    permissions: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState({
      memberPath(state) {
        return state[this.namespace].memberPath;
      },
    }),
    leavePath() {
      return this.memberPath.replace(/:id$/, 'leave');
    },
    modalTitle() {
      return sprintf(
        this.permissions.canRemoveBlockedByLastOwner
          ? this.$options.i18n.preventedTitle
          : this.$options.i18n.title,
        { source: this.member.source.fullName },
      );
    },
    preventedModalBody() {
      if (this.member.type === MEMBER_MODEL_TYPE_PROJECT_MEMBER) {
        return this.$options.i18n.preventedBodyProjectMemberModelType;
      }

      if (this.member.type === MEMBER_MODEL_TYPE_GROUP_MEMBER) {
        return this.$options.i18n.preventedBodyGroupMemberModelType;
      }

      return null;
    },
    actionPrimary() {
      if (this.permissions.canRemoveBlockedByLastOwner) {
        return null;
      }

      return {
        text: __('Leave'),
        attributes: {
          variant: 'danger',
        },
      };
    },
    obstacles() {
      return parseUserDeletionObstacles(this.member.user);
    },
    hasObstaclesToUserDeletion() {
      return this.obstacles?.length;
    },
  },
  methods: {
    handlePrimary() {
      this.$refs.form.$el.submit();
    },
  },
};
</script>

<template>
  <gl-modal
    v-bind="$attrs"
    :modal-id="$options.modalId"
    :title="modalTitle"
    :action-primary="actionPrimary"
    :action-cancel="$options.actionCancel"
    @primary="handlePrimary"
  >
    <gl-form ref="form" :action="leavePath" method="post">
      <p>
        <template v-if="permissions.canRemoveBlockedByLastOwner">{{ preventedModalBody }}</template>
        <gl-sprintf v-else :message="$options.i18n.body">
          <template #source>{{ member.source.fullName }}</template>
        </gl-sprintf>
      </p>

      <user-deletion-obstacles-list
        v-if="hasObstaclesToUserDeletion"
        :obstacles="obstacles"
        :is-current-user="true"
      />

      <input type="hidden" name="_method" value="delete" />
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    </gl-form>
  </gl-modal>
</template>

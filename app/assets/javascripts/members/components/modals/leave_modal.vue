<script>
import { GlModal, GlForm, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { mapState } from 'vuex';
import csrf from '~/lib/utils/csrf';
import { __, s__, sprintf } from '~/locale';
import UserDeletionObstaclesList from '~/vue_shared/components/user_deletion_obstacles/user_deletion_obstacles_list.vue';
import { parseUserDeletionObstacles } from '~/vue_shared/components/user_deletion_obstacles/utils';
import { LEAVE_MODAL_ID } from '../../constants';

export default {
  name: 'LeaveModal',
  actionCancel: {
    text: __('Cancel'),
  },
  actionPrimary: {
    text: __('Leave'),
    attributes: {
      variant: 'danger',
    },
  },
  csrf,
  modalId: LEAVE_MODAL_ID,
  modalContent: s__('Members|Are you sure you want to leave "%{source}"?'),
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
      return sprintf(s__('Members|Leave "%{source}"'), { source: this.member.source.fullName });
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
    :action-primary="$options.actionPrimary"
    :action-cancel="$options.actionCancel"
    @primary="handlePrimary"
  >
    <gl-form ref="form" :action="leavePath" method="post">
      <p>
        <gl-sprintf :message="$options.modalContent">
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

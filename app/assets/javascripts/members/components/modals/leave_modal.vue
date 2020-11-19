<script>
import { mapState } from 'vuex';
import { GlModal, GlForm, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { __, s__, sprintf } from '~/locale';
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
  components: { GlModal, GlForm, GlSprintf },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    member: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['memberPath']),
    leavePath() {
      return this.memberPath.replace(/:id$/, 'leave');
    },
    modalTitle() {
      return sprintf(s__('Members|Leave "%{source}"'), { source: this.member.source.name });
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
    size="sm"
    @primary="handlePrimary"
  >
    <gl-form ref="form" :action="leavePath" method="post">
      <p>
        <gl-sprintf :message="$options.modalContent">
          <template #source>{{ member.source.name }}</template>
        </gl-sprintf>
      </p>

      <input type="hidden" name="_method" value="delete" />
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    </gl-form>
  </gl-modal>
</template>

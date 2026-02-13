<script>
import { GlSprintf, GlModal } from '@gitlab/ui';
import { s__, __ } from '~/locale';

export default {
  name: 'WorkItemsSavedViewsNotFoundModal',
  components: {
    GlModal,
    GlSprintf,
  },
  modal: {
    title: s__('WorkItem|View not found'),
    body: s__(
      'WorkItem|This view either no longer exists or you do not have access to it. Make sure the view exists and the visibility is set to %{boldStart}Shared%{boldEnd} if you are not the owner.',
    ),
    actionPrimary: {
      text: __('Dismiss'),
      attributes: {
        variant: 'default',
      },
    },
  },
  props: {
    show: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['hide'],
  methods: {
    handleClose() {
      if (this.$route.query.sv_not_found) {
        this.$router.replace({ query: null });
      }
      this.$emit('hide');
    },
  },
};
</script>
<template>
  <gl-modal
    modal-id="saved-view-not-found"
    :aria-label="$options.modal.title"
    :title="$options.modal.title"
    :visible="show"
    :action-primary="$options.modal.actionPrimary"
    body-class="!gl-pb-0"
    size="sm"
    @hide="handleClose"
  >
    <gl-sprintf :message="$options.modal.body">
      <template #bold="{ content }">
        <span class="gl-font-bold">{{ content }}</span>
      </template>
    </gl-sprintf>
  </gl-modal>
</template>

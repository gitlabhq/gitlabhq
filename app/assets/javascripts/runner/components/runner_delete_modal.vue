<script>
import { GlModal } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';

const I18N_TITLE = s__('Runners|Delete runner %{name}?');
const I18N_BODY = s__(
  'Runners|The runner will be permanently deleted and no longer available for projects or groups in the instance. Are you sure you want to continue?',
);
const I18N_PRIMARY = s__('Runners|Delete runner');
const I18N_CANCEL = __('Cancel');

export default {
  components: {
    GlModal,
  },
  props: {
    runnerName: {
      type: String,
      required: true,
    },
  },
  computed: {
    title() {
      return sprintf(I18N_TITLE, { name: this.runnerName });
    },
  },
  methods: {
    onPrimary() {
      this.$refs.modal.hide();
    },
  },
  actionPrimary: { text: I18N_PRIMARY, attributes: { variant: 'danger' } },
  actionCancel: { text: I18N_CANCEL },
  I18N_BODY,
};
</script>

<template>
  <gl-modal
    ref="modal"
    size="sm"
    :title="title"
    :action-primary="$options.actionPrimary"
    :action-cancel="$options.actionCancel"
    v-bind="$attrs"
    v-on="$listeners"
    @primary="onPrimary"
  >
    {{ $options.I18N_BODY }}
  </gl-modal>
</template>

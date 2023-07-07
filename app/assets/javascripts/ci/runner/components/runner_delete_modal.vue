<script>
import { GlModal } from '@gitlab/ui';
import { __, s__, n__, sprintf } from '~/locale';

const I18N_TITLE = s__('Runners|Delete runner %{name}?');
const I18N_TITLE_PLURAL = s__('Runners|Delete %{count} runners?');
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
    managersCount: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    count() {
      // Only show count if MORE than 1 manager, for 0 we still
      // assume 1 runner that happens to be disconnected.
      return this.managersCount > 1 ? this.managersCount : 1;
    },
    title() {
      if (this.count === 1) {
        return sprintf(I18N_TITLE, { name: this.runnerName });
      }
      return sprintf(I18N_TITLE_PLURAL, { count: this.count });
    },
    body() {
      return n__(
        'Runners|The runner will be permanently deleted and no longer available for projects or groups in the instance. Are you sure you want to continue?',
        'Runners|%d runners will be permanently deleted and no longer available for projects or groups in the instance. Are you sure you want to continue?',
        this.count,
      );
    },
    actionPrimary() {
      return {
        text: n__(
          'Runners|Permanently delete runner',
          'Runners|Permanently delete %d runners',
          this.count,
        ),
        attributes: { variant: 'danger' },
      };
    },
  },
  methods: {
    show() {
      this.$refs.modal.show();
    },
    onPrimary() {
      this.$refs.modal.hide();
    },
  },
  ACTION_CANCEL: { text: I18N_CANCEL },
};
</script>

<template>
  <gl-modal
    ref="modal"
    size="sm"
    :title="title"
    :action-primary="actionPrimary"
    :action-cancel="$options.ACTION_CANCEL"
    v-bind="$attrs"
    v-on="$listeners"
    @primary="onPrimary"
  >
    {{ body }}
  </gl-modal>
</template>

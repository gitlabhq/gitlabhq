<script>
import { GlModal } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';

/**
 * This component keeps the GlModal's visibility in sync with the given vuex module.
 */
export default {
  components: {
    GlModal,
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    modalModule: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState({
      isVisible(state) {
        return state[this.modalModule].isVisible;
      },
    }),
    attrs() {
      const { modalId, modalModule, ...attrs } = this.$attrs;

      return attrs;
    },
  },
  watch: {
    isVisible(val) {
      return val ? this.bsShow() : this.bsHide();
    },
  },
  methods: {
    ...mapActions({
      syncShow(dispatch) {
        return dispatch(`${this.modalModule}/show`);
      },
      syncHide(dispatch) {
        return dispatch(`${this.modalModule}/hide`);
      },
    }),
    bsShow() {
      this.$root.$emit(BV_SHOW_MODAL, this.modalId);
    },
    bsHide() {
      // $root.$emit is a workaround because other b-modal approaches don't work yet with gl-modal
      this.$root.$emit(BV_HIDE_MODAL, this.modalId);
    },
    cancel() {
      this.$emit('cancel');
      this.syncHide();
    },
    ok() {
      this.$emit('ok');
      this.syncHide();
    },
  },
};
</script>

<template>
  <gl-modal
    v-bind="attrs"
    :modal-id="modalId"
    v-on="$listeners"
    @shown="syncShow"
    @hidden="syncHide"
  >
    <slot></slot>
    <template #modal-footer>
      <slot name="modal-footer" :ok="ok" :cancel="cancel"></slot>
    </template>
  </gl-modal>
</template>

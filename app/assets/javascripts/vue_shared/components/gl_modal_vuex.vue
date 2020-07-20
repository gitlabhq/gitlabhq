<script>
import { mapState, mapActions } from 'vuex';
import { GlModal } from '@gitlab/ui';

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
      this.$root.$emit('bv::show::modal', this.modalId);
    },
    bsHide() {
      // $root.$emit is a workaround because other b-modal approaches don't work yet with gl-modal
      this.$root.$emit('bv::hide::modal', this.modalId);
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
    <slot slot="modal-footer" name="modal-footer" :ok="ok" :cancel="cancel"></slot>
  </gl-modal>
</template>

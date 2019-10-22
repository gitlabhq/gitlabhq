<script>
export default {
  props: {
    modalConfiguration: {
      required: true,
      type: Object,
    },
    actionModals: {
      required: true,
      type: Object,
    },
    csrfToken: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      currentModalData: null,
    };
  },
  computed: {
    activeModal() {
      if (!this.currentModalData) return null;
      const { glModalAction: action } = this.currentModalData;

      return this.actionModals[action];
    },

    modalProps() {
      const { glModalAction: requestedAction } = this.currentModalData;
      return {
        ...this.modalConfiguration[requestedAction],
        ...this.currentModalData,
        csrfToken: this.csrfToken,
      };
    },
  },

  mounted() {
    document.addEventListener('click', this.handleClick);
  },

  beforeDestroy() {
    document.removeEventListener('click', this.handleClick);
  },

  methods: {
    handleClick(e) {
      const { glModalAction: action } = e.target.dataset;
      if (!action) return;

      this.show(e.target.dataset);
      e.preventDefault();
    },

    show(modalData) {
      const { glModalAction: requestedAction } = modalData;
      if (!this.actionModals[requestedAction]) {
        throw new Error(`Requested non-existing modal action ${requestedAction}`);
      }
      if (!this.modalConfiguration[requestedAction]) {
        throw new Error(`Modal action ${requestedAction} has no configuration in HTML`);
      }

      this.currentModalData = modalData;

      return this.$nextTick().then(() => {
        this.$refs.modal.show();
      });
    },
  },
};
</script>
<template>
  <div :is="activeModal" v-if="activeModal" ref="modal" v-bind="modalProps" />
</template>

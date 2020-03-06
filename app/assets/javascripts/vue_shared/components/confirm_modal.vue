<script>
import { GlModal } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';

export default {
  components: {
    GlModal,
  },
  props: {
    modalAttributes: {
      type: Object,
      required: false,
      default: () => {
        return {};
      },
    },
    path: {
      type: String,
      required: false,
      default: '',
    },
    method: {
      type: String,
      required: false,
      default: '',
    },
    showModal: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  watch: {
    showModal(val) {
      if (val) {
        // Wait for v-if to render
        this.$nextTick(() => {
          this.openModal();
        });
      }
    },
  },
  methods: {
    openModal() {
      this.$refs.modal.show();
    },
    submitModal() {
      this.$refs.form.submit();
    },
  },
  csrf,
};
</script>

<template>
  <gl-modal
    v-if="showModal"
    ref="modal"
    v-bind="modalAttributes"
    @primary="submitModal"
    @canceled="$emit('dismiss')"
  >
    <form ref="form" :action="path" method="post">
      <!-- Rails workaround for <form method="delete" />
      https://github.com/rails/rails/blob/master/actionview/app/assets/javascripts/rails-ujs/features/method.coffee
      -->
      <input type="hidden" name="_method" :value="method" />
      <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
      <div>{{ modalAttributes.message }}</div>
    </form>
  </gl-modal>
</template>

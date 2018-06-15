<script>
import { mapActions } from 'vuex';
import LoadingIcon from '../../vue_shared/components/loading_icon.vue';

export default {
  components: {
    LoadingIcon,
  },
  props: {
    message: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  methods: {
    ...mapActions(['setErrorMessage']),
    clickAction() {
      if (this.isLoading) return;

      this.isLoading = true;

      this.$store
        .dispatch(this.message.action, this.message.actionPayload)
        .then(() => {
          this.isLoading = false;
        })
        .catch(() => {
          this.isLoading = false;
        });
    },
    clickFlash() {
      if (!this.message.action) {
        this.setErrorMessage(null);
      }
    },
  },
};
</script>

<template>
  <div
    class="flash-container flash-container-page"
    @click="clickFlash"
  >
    <div class="flash-alert">
      <span
        v-html="message.text"
      >
      </span>
      <a
        v-if="message.action"
        href="#"
        class="flash-action"
        @click.stop.prevent="clickAction"
      >
        {{ message.actionText }}
        <loading-icon
          v-show="isLoading"
          inline
        />
      </a>
    </div>
  </div>
</template>

<style scoped>
.flash-action {
  color: #fff;
}
</style>

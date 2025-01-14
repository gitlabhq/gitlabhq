<script>
import { GlButton, GlModal } from '@gitlab/ui';
import { createAlert, VARIANT_SUCCESS, VARIANT_WARNING } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';
import {
  CONFIRM_MODAL,
  CONFIRM_MODAL_TITLE,
  COPY_SECRET,
  DESCRIPTION_SECRET,
  RENEW_SECRET,
  RENEW_SECRET_FAILURE,
  RENEW_SECRET_SUCCESS,
  WARNING_NO_SECRET,
} from '../constants';

export default {
  CONFIRM_MODAL,
  CONFIRM_MODAL_TITLE,
  COPY_SECRET,
  DESCRIPTION_SECRET,
  RENEW_SECRET,
  name: 'OAuthSecret',
  components: {
    GlButton,
    GlModal,
    InputCopyToggleVisibility,
  },
  inject: ['initialSecret', 'renewPath'],
  data() {
    return {
      secret: this.initialSecret,
      alert: null,
      isModalVisible: false,
      isLoading: false,
    };
  },
  computed: {
    actionPrimary() {
      return {
        text: this.$options.RENEW_SECRET,
        attributes: {
          variant: 'confirm',
          loading: this.isLoading,
        },
      };
    },
  },
  created() {
    if (!this.secret) {
      this.alert = createAlert({ message: WARNING_NO_SECRET, variant: VARIANT_WARNING });
    }
  },
  methods: {
    displayModal() {
      this.isModalVisible = true;
    },
    async renewSecret(event) {
      event.preventDefault();
      this.isLoading = true;
      this.alert?.dismiss();

      try {
        const { data } = await axios.put(this.renewPath);
        this.alert = createAlert({ message: RENEW_SECRET_SUCCESS, variant: VARIANT_SUCCESS });
        this.secret = data.secret;
      } catch {
        this.alert = createAlert({ message: RENEW_SECRET_FAILURE });
      } finally {
        this.isLoading = false;
        this.isModalVisible = false;
      }
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-wrap gl-gap-5">
    <input-copy-toggle-visibility
      v-if="secret"
      :copy-button-title="$options.COPY_SECRET"
      :value="secret"
      readonly
      class="-gl-mt-3 gl-mb-0"
    >
      <template #description>
        {{ $options.DESCRIPTION_SECRET }}
      </template>
    </input-copy-toggle-visibility>

    <gl-button category="secondary" class="gl-self-start" @click="displayModal">{{
      $options.RENEW_SECRET
    }}</gl-button>

    <gl-modal
      v-model="isModalVisible"
      :title="$options.CONFIRM_MODAL_TITLE"
      size="sm"
      modal-id="modal-renew-secret"
      :action-primary="actionPrimary"
      @primary="renewSecret"
    >
      {{ $options.CONFIRM_MODAL }}
    </gl-modal>
  </div>
</template>

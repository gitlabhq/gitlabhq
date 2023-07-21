<script>
import { nextTick } from 'vue';
import { GlForm, GlButton } from '@gitlab/ui';
import { VARIANT_DANGER, VARIANT_INFO, createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { readFileAsDataURL } from '~/lib/utils/file_utility';

import { i18n } from '../constants';
import UserAvatar from './user_avatar.vue';

export default {
  components: {
    UserAvatar,
    GlForm,
    GlButton,
  },
  props: {
    profilePath: {
      type: String,
      required: true,
    },
    userPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      uploadingProfile: false,
      avatarBlob: null,
    };
  },
  methods: {
    async onSubmit() {
      // TODO: Do validation before organizing data.
      this.uploadingProfile = true;
      const formData = new FormData();

      if (this.avatarBlob) {
        formData.append('user[avatar]', this.avatarBlob, 'avatar.png');
      }

      try {
        const { data } = await axios.put(this.profilePath, formData);

        if (this.avatarBlob) {
          this.syncHeaderAvatars();
        }

        createAlert({
          message: data.message,
          variant: data.status === 'error' ? VARIANT_DANGER : VARIANT_INFO,
        });

        nextTick(() => {
          window.scrollTo(0, 0);
          this.uploadingProfile = false;
        });
      } catch (e) {
        createAlert({
          message: e.message,
          variant: VARIANT_DANGER,
        });
        this.updateProfileSettings = false;
      }
    },
    async syncHeaderAvatars() {
      const dataURL = await readFileAsDataURL(this.avatarBlob);

      // TODO: implement sync for super sidebar
      ['.header-user-avatar', '.js-sidebar-user-avatar'].forEach((selector) => {
        const node = document.querySelector(selector);
        if (!node) return;

        node.setAttribute('src', dataURL);
        node.setAttribute('srcset', dataURL);
      });
    },
    onBlobChange(blob) {
      this.avatarBlob = blob;
    },
  },
  i18n,
};
</script>

<template>
  <gl-form @submit.prevent="onSubmit">
    <user-avatar @blob-change="onBlobChange" />
    <!-- TODO: to implement profile editing form fields -->
    <!-- It will be implemented in the upcoming MRs -->
    <!-- Related issue: https://gitlab.com/gitlab-org/gitlab/-/issues/389918 -->
    <div class="js-hide-when-nothing-matches-search gl-border-t gl-py-6">
      <gl-button
        variant="confirm"
        type="submit"
        class="gl-mr-3 js-password-prompt-btn"
        :disabled="uploadingProfile"
      >
        {{ $options.i18n.updateProfileSettings }}
      </gl-button>
      <gl-button :href="userPath" data-testid="cancel-edit-button">
        {{ $options.i18n.cancel }}
      </gl-button>
    </div>
  </gl-form>
</template>

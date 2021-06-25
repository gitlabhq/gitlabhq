<script>
import { GlModal, GlFormGroup, GlFormInput, GlSprintf } from '@gitlab/ui';
import { isSafeURL } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { YOUTUBE_URL, YOUTUBE_EMBED_URL } from '../constants';

export default {
  components: {
    GlModal,
    GlFormGroup,
    GlFormInput,
    GlSprintf,
  },
  data() {
    return {
      url: null,
      urlError: null,
      description: __(
        'If the YouTube URL is https://www.youtube.com/watch?v=0t1DgySidms then the video ID is %{id}',
      ),
    };
  },
  modalTitle: __('Insert a video'),
  okTitle: __('Insert video'),
  label: __('YouTube URL or ID'),
  methods: {
    show() {
      this.urlError = null;
      this.url = null;

      this.$refs.modal.show();
    },
    onPrimary(event) {
      this.submitURL(event);
    },
    submitURL(event) {
      const url = this.generateUrl();

      if (!url) {
        event.preventDefault();
        return;
      }

      this.$emit('insertVideo', url);
    },
    generateUrl() {
      let { url } = this;
      const reYouTubeId = /^[A-z0-9]*$/;
      const reYouTubeUrl = RegExp(`${YOUTUBE_URL}/(embed/|watch\\?v=)([A-z0-9]+)`);

      if (reYouTubeId.test(url)) {
        url = `${YOUTUBE_EMBED_URL}/${url}`;
      } else if (reYouTubeUrl.test(url)) {
        url = `${YOUTUBE_EMBED_URL}/${reYouTubeUrl.exec(url)[2]}`;
      }

      if (!isSafeURL(url) || !reYouTubeUrl.test(url)) {
        this.urlError = __('Please provide a valid YouTube URL or ID');
        this.$refs.urlInput.$el.focus();
        return null;
      }

      return url;
    },
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    size="sm"
    modal-id="insert-video-modal"
    :title="$options.modalTitle"
    :ok-title="$options.okTitle"
    @primary="onPrimary"
  >
    <gl-form-group
      :label="$options.label"
      label-for="video-modal-url-input"
      :state="!Boolean(urlError)"
      :invalid-feedback="urlError"
    >
      <gl-form-input id="video-modal-url-input" ref="urlInput" v-model="url" />
      <template #description>
        <gl-sprintf :message="description" class="text-gl-muted">
          <template #id>
            <strong>{{ __('0t1DgySidms') }}</strong>
          </template>
        </gl-sprintf>
      </template>
    </gl-form-group>
  </gl-modal>
</template>

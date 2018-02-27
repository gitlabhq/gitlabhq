<script>
  import axios from '~/lib/utils/axios_utils';
  import { saveFlashMessage } from '~/lib/utils/flash_queue';
  import createFlash from '~/flash';
  import GlModal from '~/vue_shared/components/gl_modal.vue';
  import { redirectTo } from '~/lib/utils/url_utility';
  import { s__, sprintf } from '~/locale';
  import eventHub from '../event_hub';

  export default {
    components: {
      GlModal,
    },
    props: {
      url: {
        type: String,
        required: true,
      },
      labelTitle: {
        type: String,
        required: true,
      },
      labelColor: {
        type: String,
        required: true,
      },
      labelTextColor: {
        type: String,
        required: true,
      },
    },
    computed: {
      text() {
        return s__(`Milestones|Promoting this label will make it available for all projects inside the group. 
        Existing project labels with the same name will be merged. This action cannot be reversed.`);
      },
      title() {
        const label = `<span
          class="label color-label"
          style="background-color: ${this.labelColor}; color: ${this.labelTextColor};"
        >${this.labelTitle}</span>`;

        return sprintf(s__('Labels|Promote label %{labelTitle} to Group Label?'), {
          labelTitle: label,
        }, false);
      },
    },
    methods: {
      onSubmit() {
        eventHub.$emit('promoteLabelModal.requestStarted', this.url);
        return axios.post(this.url)
          .then((response) => {
            eventHub.$emit('promoteLabelModal.requestFinished', { labelUrl: this.url, successful: true });
            const responseURL = new URL(response.request.responseURL);
            const bodyData = responseURL.searchParams.get('body_data');
            saveFlashMessage(bodyData, `${this.labelTitle} promoted to group label`, 'notice');
            redirectTo(`${responseURL.protocol}//${responseURL.host}${responseURL.pathname}`);
          })
          .catch((error) => {
            eventHub.$emit('promoteLabelModal.requestFinished', { labelUrl: this.url, successful: false });
            createFlash(error);
          });
      },
    },
  };
</script>
<template>
  <gl-modal
    id="promote-label-modal"
    footer-primary-button-variant="warning"
    :footer-primary-button-text="s__('Labels|Promote Label')"
    @submit="onSubmit"
  >
    <div
      slot="title"
      v-html="title"
    >
      {{ title }}
    </div>

    {{ text }}
  </gl-modal>
</template>

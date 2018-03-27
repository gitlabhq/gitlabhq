<script>
  import axios from '~/lib/utils/axios_utils';
  import createFlash from '~/flash';
  import GlModal from '~/vue_shared/components/gl_modal.vue';
  import { s__, sprintf } from '~/locale';
  import { visitUrl } from '~/lib/utils/url_utility';
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
        Existing project labels with the same title will be merged. This action cannot be reversed.`);
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
        return axios.post(this.url, { params: { format: 'json' } })
          .then((response) => {
            eventHub.$emit('promoteLabelModal.requestFinished', { labelUrl: this.url, successful: true });
            visitUrl(response.data.url);
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

<script>
  import axios from '~/lib/utils/axios_utils';
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
      milestoneTitle: {
        type: String,
        required: true,
      },
      url: {
        type: String,
        required: true,
      },
    },
    computed: {
      title() {
        return sprintf(s__('Milestones|Promote %{title} to group milestone?'), { title: this.milestoneTitle });
      },
      text() {
        return s__(`Milestones|Promoting this milestone will make it available for all projects inside the group.
        Existing project milestones with the same name will be merged.
        This action cannot be reversed.`);
      },
    },
    methods: {
      onSubmit() {
        eventHub.$emit('promoteMilestoneModal.requestStarted', this.url);
        return axios.post(this.url)
          .then((response) => {
            eventHub.$emit('promoteMilestoneModal.requestFinished', { labelUrl: this.url, successful: true });
            redirectTo(response.request.responseURL);
          })
          .catch((error) => {
            eventHub.$emit('promoteMilestoneModal.requestFinished', { labelUrl: this.url, successful: true });
            createFlash(error);
          });
      },
    },
  };
</script>
<template>
  <gl-modal
    id="promote-milestone-modal"
    footer-primary-button-variant="warning"
    :footer-primary-button-text="s__('Milestones|Promote Milestone')"
    @submit="onSubmit"
  >
    <div
      slot="title"
    >
      {{ title }}
    </div>
    {{ text }}
  </gl-modal>
</template>


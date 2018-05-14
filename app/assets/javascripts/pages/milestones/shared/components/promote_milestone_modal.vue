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
      milestoneTitle: {
        type: String,
        required: true,
      },
      url: {
        type: String,
        required: true,
      },
      groupName: {
        type: String,
        required: true,
      },
    },
    computed: {
      title() {
        return sprintf(s__('Milestones|Promote %{milestoneTitle} to group milestone?'), { milestoneTitle: this.milestoneTitle });
      },
      text() {
        return sprintf(s__(`Milestones|Promoting %{milestoneTitle} will make it available for all projects inside %{groupName}.
        Existing project milestones with the same title will be merged.
        This action cannot be reversed.`), { milestoneTitle: this.milestoneTitle, groupName: this.groupName });
      },
    },
    methods: {
      onSubmit() {
        eventHub.$emit('promoteMilestoneModal.requestStarted', this.url);
        return axios.post(this.url, { params: { format: 'json' } })
          .then((response) => {
            eventHub.$emit('promoteMilestoneModal.requestFinished', { milestoneUrl: this.url, successful: true });
            visitUrl(response.data.url);
          })
          .catch((error) => {
            eventHub.$emit('promoteMilestoneModal.requestFinished', { milestoneUrl: this.url, successful: false });
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
    <template
      slot="title"
    >
      {{ title }}
    </template>
    {{ text }}
  </gl-modal>
</template>


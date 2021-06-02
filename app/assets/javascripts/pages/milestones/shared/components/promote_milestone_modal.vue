<script>
import { GlModal } from '@gitlab/ui';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';

export default {
  components: {
    GlModal,
  },
  data() {
    return {
      milestoneTitle: '',
      url: '',
      groupName: '',
      currentButton: null,
      visible: false,
    };
  },
  computed: {
    title() {
      return sprintf(s__('Milestones|Promote %{milestoneTitle} to group milestone?'), {
        milestoneTitle: this.milestoneTitle,
      });
    },
    text() {
      return sprintf(
        s__(`Milestones|Promoting %{milestoneTitle} will make it available for all projects inside %{groupName}.
        Existing project milestones with the same title will be merged.`),
        { milestoneTitle: this.milestoneTitle, groupName: this.groupName },
      );
    },
  },
  mounted() {
    this.getButtons().forEach((button) => {
      button.addEventListener('click', this.onPromoteButtonClick);
      button.removeAttribute('disabled');
    });
  },
  beforeDestroy() {
    this.getButtons().forEach((button) => {
      button.removeEventListener('click', this.onPromoteButtonClick);
    });
  },
  methods: {
    onPromoteButtonClick({ currentTarget }) {
      const { milestoneTitle, url, groupName } = currentTarget.dataset;
      currentTarget.setAttribute('disabled', '');
      this.visible = true;
      this.milestoneTitle = milestoneTitle;
      this.url = url;
      this.groupName = groupName;
      this.currentButton = currentTarget;
    },
    getButtons() {
      return document.querySelectorAll('.js-promote-project-milestone-button');
    },
    onSubmit() {
      return axios
        .post(this.url, { params: { format: 'json' } })
        .then((response) => {
          visitUrl(response.data.url);
        })
        .catch((error) => {
          createFlash({
            message: error,
          });
        })
        .finally(() => {
          this.visible = false;
        });
    },
    onClose() {
      this.visible = false;
      if (this.currentButton) {
        this.currentButton.removeAttribute('disabled');
      }
    },
  },
  primaryAction: {
    text: s__('Milestones|Promote Milestone'),
    attributes: [{ variant: 'warning' }],
  },
  cancelAction: {
    text: s__('Cancel'),
    attributes: [],
  },
};
</script>
<template>
  <gl-modal
    :visible="visible"
    modal-id="promote-milestone-modal"
    :action-primary="$options.primaryAction"
    :action-cancel="$options.cancelAction"
    :title="title"
    @primary="onSubmit"
    @hide="onClose"
  >
    <p>{{ text }}</p>
    <p>{{ s__('Milestones|This action cannot be reversed.') }}</p>
  </gl-modal>
</template>

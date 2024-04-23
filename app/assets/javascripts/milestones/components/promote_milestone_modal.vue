<script>
import { GlModal } from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';

export default {
  components: {
    GlModal,
  },
  props: {
    visible: {
      type: Boolean,
      default: false,
      required: false,
    },
    milestoneTitle: {
      type: String,
      required: true,
    },
    promoteUrl: {
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
  methods: {
    onSubmit() {
      return axios
        .post(this.promoteUrl, { params: { format: 'json' } })
        .then((response) => {
          visitUrl(response.data.url);
        })
        .catch((error) => {
          createAlert({
            message: error,
          });
        })
        .finally(() => {
          this.onClose();
        });
    },
    onClose() {
      this.$emit('promotionModalVisible', false);
    },
  },
  primaryAction: {
    text: s__('Milestones|Promote Milestone'),
    attributes: { variant: 'confirm' },
  },
  cancelAction: {
    text: __('Cancel'),
    attributes: {},
  },
};
</script>
<template>
  <gl-modal
    :visible="visible"
    modal-id="promote-milestone-modal"
    :title="title"
    :action-primary="$options.primaryAction"
    :action-cancel="$options.cancelAction"
    @primary="onSubmit"
    @hide="onClose"
  >
    <p>{{ text }}</p>
    <p>{{ s__('Milestones|This action cannot be reversed.') }}</p>
  </gl-modal>
</template>

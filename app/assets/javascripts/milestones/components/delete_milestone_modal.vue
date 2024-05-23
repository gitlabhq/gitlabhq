<script>
import { GlSprintf, GlModal } from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, n__, s__, sprintf } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
    GlModal,
    GlSprintf,
  },
  props: {
    visible: {
      type: Boolean,
      default: false,
      required: false,
    },
    issueCount: {
      type: Number,
      required: true,
    },
    mergeRequestCount: {
      type: Number,
      required: true,
    },
    milestoneId: {
      type: Number,
      required: true,
    },
    milestoneTitle: {
      type: String,
      required: true,
    },
    milestoneUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    text() {
      if (this.issueCount === 0 && this.mergeRequestCount === 0) {
        return s__(`Milestones|
You’re about to permanently delete the milestone %{milestoneTitle}.
This milestone is not currently used in any issues or merge requests.`);
      }

      return sprintf(
        s__(`Milestones|
You’re about to permanently delete the milestone %{milestoneTitle} and remove it from %{issuesWithCount} and %{mergeRequestsWithCount}.
Once deleted, it cannot be undone or recovered.`),
        {
          issuesWithCount: n__('%d issue', '%d issues', this.issueCount),
          mergeRequestsWithCount: n__(
            '%d merge request',
            '%d merge requests',
            this.mergeRequestCount,
          ),
        },
        false,
      );
    },
    title() {
      return sprintf(s__('Milestones|Delete milestone %{milestoneTitle}?'), {
        milestoneTitle: this.milestoneTitle,
      });
    },
  },
  methods: {
    onSubmit() {
      eventHub.$emit('deleteMilestoneModal.requestStarted', this.milestoneUrl);

      return axios
        .delete(this.milestoneUrl)
        .then((response) => {
          eventHub.$emit('deleteMilestoneModal.requestFinished', {
            milestoneUrl: this.milestoneUrl,
            successful: true,
          });

          // follow the redirect to milestones overview page
          visitUrl(response.request.responseURL);
        })
        .catch((error) => {
          eventHub.$emit('deleteMilestoneModal.requestFinished', {
            milestoneUrl: this.milestoneUrl,
            successful: false,
          });

          if (error.response && error.response.status === HTTP_STATUS_NOT_FOUND) {
            createAlert({
              message: sprintf(s__('Milestones|Milestone %{milestoneTitle} was not found'), {
                milestoneTitle: this.milestoneTitle,
              }),
            });
          } else {
            createAlert({
              message: sprintf(s__('Milestones|Failed to delete milestone %{milestoneTitle}'), {
                milestoneTitle: this.milestoneTitle,
              }),
            });
          }
          throw error;
        })
        .finally(() => {
          this.onClose();
        });
    },
    onClose() {
      this.$emit('deleteModalVisible', false);
    },
  },
  primaryProps: {
    text: s__('Milestones|Delete milestone'),
    attributes: { variant: 'danger', category: 'primary' },
  },
  cancelProps: {
    text: __('Cancel'),
  },
};
</script>

<template>
  <gl-modal
    :visible="visible"
    modal-id="delete-milestone-modal"
    :title="title"
    :action-primary="$options.primaryProps"
    :action-cancel="$options.cancelProps"
    @primary="onSubmit"
    @hide="onClose"
  >
    <gl-sprintf :message="text">
      <template #milestoneTitle>
        <strong>{{ milestoneTitle }}</strong>
      </template>
    </gl-sprintf>
  </gl-modal>
</template>

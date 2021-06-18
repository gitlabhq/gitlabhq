<script>
import { GlSafeHtmlDirective as SafeHtml, GlModal } from '@gitlab/ui';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';

import { redirectTo } from '~/lib/utils/url_utility';
import { __, n__, s__, sprintf } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
    GlModal,
  },
  directives: {
    SafeHtml,
  },
  props: {
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
      const milestoneTitle = sprintf('<strong>%{milestoneTitle}</strong>', {
        milestoneTitle: this.milestoneTitle,
      });

      if (this.issueCount === 0 && this.mergeRequestCount === 0) {
        return sprintf(
          s__(`Milestones|
You’re about to permanently delete the milestone %{milestoneTitle}.
This milestone is not currently used in any issues or merge requests.`),
          {
            milestoneTitle,
          },
          false,
        );
      }

      return sprintf(
        s__(`Milestones|
You’re about to permanently delete the milestone %{milestoneTitle} and remove it from %{issuesWithCount} and %{mergeRequestsWithCount}.
Once deleted, it cannot be undone or recovered.`),
        {
          milestoneTitle,
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

          // follow the rediect to milestones overview page
          redirectTo(response.request.responseURL);
        })
        .catch((error) => {
          eventHub.$emit('deleteMilestoneModal.requestFinished', {
            milestoneUrl: this.milestoneUrl,
            successful: false,
          });

          if (error.response && error.response.status === 404) {
            createFlash({
              message: sprintf(s__('Milestones|Milestone %{milestoneTitle} was not found'), {
                milestoneTitle: this.milestoneTitle,
              }),
            });
          } else {
            createFlash({
              message: sprintf(s__('Milestones|Failed to delete milestone %{milestoneTitle}'), {
                milestoneTitle: this.milestoneTitle,
              }),
            });
          }
          throw error;
        });
    },
  },
  primaryProps: {
    text: s__('Milestones|Delete milestone'),
    attributes: [{ variant: 'danger' }, { category: 'primary' }],
  },
  cancelProps: {
    text: __('Cancel'),
  },
};
</script>

<template>
  <gl-modal
    modal-id="delete-milestone-modal"
    :title="title"
    :action-primary="$options.primaryProps"
    :action-cancel="$options.cancelProps"
    @primary="onSubmit"
  >
    <p v-safe-html="text"></p>
  </gl-modal>
</template>

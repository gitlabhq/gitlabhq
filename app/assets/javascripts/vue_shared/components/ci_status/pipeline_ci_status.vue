<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import pipelineCiStatus from './graphql/pipeline_ci_status.query.graphql';
import pipelineCiStatusUpdatedSubscription from './graphql/pipeline_ci_status_updated.subscription.graphql';

/*
 * Renders a real-time CI status for pipelines.
 * This component utilizes a GraphQL subscription to
 * get real-time status updates over a WebSocket.
 */

export default {
  components: {
    CiIcon,
    GlLoadingIcon,
  },
  props: {
    pipelineId: {
      type: String,
      required: true,
    },
    projectFullPath: {
      type: String,
      required: true,
    },
    // Pass a feature flag value from the related view to this prop
    // to ensure skipping the subscription is possible based on the flags value.
    canSubscribe: {
      type: Boolean,
      required: true,
    },
  },
  apollo: {
    status: {
      query: pipelineCiStatus,
      variables() {
        return {
          fullPath: this.projectFullPath,
          pipelineId: this.pipelineId,
        };
      },
      update({ project }) {
        return project?.pipeline?.detailedStatus;
      },
      skip() {
        return !this.pipelineId || !this.projectFullPath;
      },
      error(error) {
        createAlert({ message: __('An error occurred fetching the pipeline status.') });

        captureException(error);
      },
      subscribeToMore: {
        document() {
          return pipelineCiStatusUpdatedSubscription;
        },
        variables() {
          return {
            pipelineId: this.pipelineId,
          };
        },
        skip() {
          return !this.canSubscribe || !this.status;
        },
        updateQuery(
          previousData,
          {
            subscriptionData: {
              data: { ciPipelineStatusUpdated },
            },
          },
        ) {
          if (previousData && ciPipelineStatusUpdated)
            return {
              project: {
                ...previousData.project,
                pipeline: {
                  ...previousData.project.pipeline,
                  detailedStatus: ciPipelineStatusUpdated.detailedStatus,
                },
              },
            };

          return previousData;
        },
      },
    },
  },
  data() {
    return {
      status: null,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.status.loading;
    },
  },
};
</script>
<template>
  <gl-loading-icon v-if="isLoading" />
  <div v-else>
    <ci-icon v-if="status" :status="status" />
  </div>
</template>

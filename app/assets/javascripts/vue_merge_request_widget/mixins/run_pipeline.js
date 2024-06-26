import { createAlert } from '~/alert';
import { s__, __ } from '~/locale';
import Api from '~/api';
import toast from '~/vue_shared/plugins/global_toast';
import { HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  props: {
    targetProjectId: {
      type: Number,
      required: true,
    },
    iid: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      isCreatingPipeline: false,
    };
  },
  methods: {
    async runPipeline() {
      this.isCreatingPipeline = true;

      try {
        await Api.postMergeRequestPipeline(this.targetProjectId, {
          mergeRequestId: this.iid,
        });

        this.isCreatingPipeline = false;
        this.$refs.modal?.hide();

        toast(s__('Pipeline|Creating pipeline.'));
      } catch (e) {
        const unauthorized = e.response.status === HTTP_STATUS_UNAUTHORIZED;
        let errorMessage = __(
          'An error occurred while trying to run a new pipeline for this merge request.',
        );

        if (unauthorized) {
          errorMessage = __('You do not have permission to run a pipeline on this branch.');
        }

        createAlert({
          message: errorMessage,
          primaryButton: {
            text: __('Learn more'),
            link: helpPagePath('ci/pipelines/merge_request_pipelines.md'),
          },
        });

        this.isCreatingPipeline = false;
      }
    },
  },
};

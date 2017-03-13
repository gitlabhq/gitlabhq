import mrWidgetPipeline from '../../components/mr_widget_pipeline';
import mrWidgetMergeHelp from '../../components/mr_widget_merge_help';

export default {
  name: 'MRWidgetReadyToMerge',
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  components: {
    'mr-widget-pipeline': mrWidgetPipeline,
    'mr-widget-merge-help': mrWidgetMergeHelp,
  },
  data() {
    return {
      removeSourceBranch: false,
      mergeWhenBuildSucceeds: false,
      useCommitMessageWithDescription: false,
      setToMergeWhenBuildSucceeds: false,
      showCommitMessageEditor: false,
      commitMessage: this.mr.commitMessage,
    };
  },
  computed: {
    commitMessageLinkTitle() {
      const withDesc = 'Include description in commit message';
      const withoutDesc = "Don't include description in commit message";

      return this.useCommitMessageWithDescription ? withoutDesc : withDesc;
    },
    mergeButtonClass() {
      const defaultCls = 'btn btn-success';
      const failedCls = `${defaultCls} btn-danger`;
      const { pipeline } = this.mr;

      if (!pipeline) {
        return defaultCls;
      }

      return pipeline.details.status.label === 'failed' ? failedCls : defaultCls;
    },
  },
  methods: {
    updateCommitMessage() {
      const cmwd = this.mr.commitMessageWithDescription;
      this.useCommitMessageWithDescription = !this.useCommitMessageWithDescription;
      this.commitMessage = this.useCommitMessageWithDescription ? cmwd : this.mr.commitMessage;
    },
    toggleCommitMessageEditor() {
      this.showCommitMessageEditor = !this.showCommitMessageEditor;
    },
    merge() {
      const options = {
        sha: this.mr.sha,
        merge_when_build_succeeds: this.setToMergeWhenBuildSucceeds,
        commit_message: this.commitMessage,
        should_remove_source_branch: this.removeSourceBranch,
      };

      // TODO: Handle success and error case when backend returns JSON
      this.service.merge(options);
    },
  },
  template: `
    <div class="mr-widget-wrapper">
      <mr-widget-pipeline v-if="mr.pipeline" :mr="mr" />
      <div class="mr-widget-body">
        <button
          @click="merge"
          :disabled="!commitMessage.length"
          :class="mergeButtonClass">Merge</button>
        <label><input type="checkbox" v-model="removeSourceBranch" /> Remove source branch</label>
        <a @click.prevent="toggleCommitMessageEditor"
          class="btn btn-default btn-xs" href="#">Modify commit message</a>
        <div class="prepend-top-default clearfix" v-if="showCommitMessageEditor">
          <div class="form-group">
            <label class="control-label" for="commit-message">Commit message</label>
            <div class="col-sm-10">
              <div class="commit-message-container">
                <div class="max-width-marker"></div>
                <textarea
                  v-model="commitMessage"
                  class="form-control js-commit-message" required="required" rows="14"></textarea>
              </div>
              <p class="hint">Try to keep the first line under 52 characters and the others under 72.</p>
              <div class="hint">
                <a @click.prevent="updateCommitMessage" href="#">{{commitMessageLinkTitle}}</a>
              </div>
            </div>
          </div>
        </div>
        <mr-widget-merge-help />
      </div>
    </div>
  `,
};

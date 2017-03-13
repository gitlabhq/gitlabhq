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
      const inActionCls = `${defaultCls} btn-info`;
      const { pipeline } = this.mr;

      if (!pipeline) {
        return defaultCls;
      } else if (this.mr.isPipelineActive) {
        return inActionCls;
      } else if (this.mr.isPipelineFailed) {
        return failedCls;
      }

      return defaultCls;
    },
    mergeButtonText() {
      if (this.mr.isPipelineActive) {
        return 'Merge when pipeline succeeds';
      }

      return 'Merge';
    },
    shouldShowMergeOptionsDropdown() {
      return this.mr.isPipelineActive && !this.mr.onlyAllowMergeIfPipelineSucceeds;
    },
    isMergeButtonDisabled() {
      const { mr, commitMessage } = this;
      return !commitMessage.length || !this.isMergeAllowed();
    },
  },
  methods: {
    isMergeAllowed() {
      return !(this.mr.onlyAllowMergeIfPipelineSucceeds && this.mr.isPipelineFailed);
    },
    updateCommitMessage() {
      const cmwd = this.mr.commitMessageWithDescription;
      this.useCommitMessageWithDescription = !this.useCommitMessageWithDescription;
      this.commitMessage = this.useCommitMessageWithDescription ? cmwd : this.mr.commitMessage;
    },
    toggleCommitMessageEditor() {
      this.showCommitMessageEditor = !this.showCommitMessageEditor;
    },
    handleMergeButtonClick(mergeWhenBuildSucceeds) {
      if (mergeWhenBuildSucceeds === undefined) {
        const { isPipelineActive } = this.mr;
        mergeWhenBuildSucceeds = isPipelineActive; // eslint-disable-line no-param-reassign
      }

      this.setToMergeWhenBuildSucceeds = mergeWhenBuildSucceeds ? 1 : 0;

      const options = {
        sha: this.mr.sha,
        merge_when_build_succeeds: this.setToMergeWhenBuildSucceeds,
        commit_message: this.commitMessage,
        should_remove_source_branch: this.removeSourceBranch,
      };

      this.service.merge(options);
    },
  },
  template: `
    <div class="mr-widget-wrapper">
      <mr-widget-pipeline v-if="mr.pipeline" :mr="mr" />
      <div class="mr-widget-body">
        <span class="btn-group">
          <button
            @click="handleMergeButtonClick()"
            :disabled="isMergeButtonDisabled"
            :class="mergeButtonClass">{{mergeButtonText}}</button>
          <button
            v-if="shouldShowMergeOptionsDropdown"
            class="btn btn-info dropdown-toggle" data-toggle="dropdown">
            <i class="fa fa-caret-down"></i>
            <span class="sr-only">Select Merge Moment</span>
          </button>
          <ul
            v-if="shouldShowMergeOptionsDropdown"
            class="dropdown-menu dropdown-menu-right" role="menu">
            <li>
              <a
                @click.prevent="handleMergeButtonClick(true)"
                class="merge_when_pipeline_succeeds" href="#">
                <i class="fa fa-check fa-fw"></i> Merge when pipeline succeeds
              </a>
            </li>
            <li>
              <a
                @click.prevent="handleMergeButtonClick(false)"
                class="accept-merge-request" href="#">
                <i class="fa fa-warning fa-fw"></i> Merge immediately
              </a>
            </li>
          </ul>
        </span>
        <div v-if="isMergeAllowed()">
          <label>
            <input type="checkbox" v-model="removeSourceBranch" /> Remove source branch
          </label>
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
        </div>
        <div v-else>
          <span class="bold">
            The pipeline for this merge request failed. Please retry the job or push a new commit to fix the failure.
          </span>
        </div>
        <mr-widget-merge-help />
      </div>
    </div>
  `,
};

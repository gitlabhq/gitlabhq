import eventHub from '../../event_hub';

export default {
  name: 'MRWidgetReadyToMerge',
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  data() {
    return {
      removeSourceBranch: true,
      mergeWhenBuildSucceeds: false,
      useCommitMessageWithDescription: false,
      setToMergeWhenPipelineSucceeds: false,
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
      const defaultClass = 'btn btn-success';
      const failedClass = `${defaultClass} btn-danger`;
      const inActionClass = `${defaultClass} btn-info`;
      const { pipeline, isPipelineActive, isPipelineFailed, hasCI, ciStatus } = this.mr;

      if (hasCI && !ciStatus) {
        return failedClass;
      } else if (!pipeline) {
        return defaultClass;
      } else if (isPipelineActive) {
        return inActionClass;
      } else if (isPipelineFailed) {
        return failedClass;
      }

      return defaultClass;
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
      const { commitMessage } = this;
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
        mergeWhenBuildSucceeds = this.mr.isPipelineActive; // eslint-disable-line no-param-reassign
      }

      this.setToMergeWhenPipelineSucceeds = mergeWhenBuildSucceeds === true;

      const options = {
        sha: this.mr.sha,
        commit_message: this.commitMessage,
        merge_when_pipeline_succeeds: this.setToMergeWhenPipelineSucceeds,
        should_remove_source_branch: this.removeSourceBranch === true,
      };

      // TODO: Error handling
      this.service.merge(options)
        .then(res => res.json())
        .then((res) => {
          if (res.status === 'merge_when_pipeline_succeeds') {
            eventHub.$emit('MRWidgetUpdateRequested');
          }
        });
    },
  },
  template: `
    <div class="mr-widget-body">
      <span class="btn-group">
        <button
          @click="handleMergeButtonClick()"
          :disabled="isMergeButtonDisabled"
          :class="mergeButtonClass"
          type="button">{{mergeButtonText}}</button>
        <button
          v-if="shouldShowMergeOptionsDropdown"
          type="button" class="btn btn-info dropdown-toggle" data-toggle="dropdown">
          <i class="fa fa-caret-down" aria-hidden="true"></i>
          <span class="sr-only">Select Merge Moment</span>
        </button>
        <ul
          v-if="shouldShowMergeOptionsDropdown"
          class="dropdown-menu dropdown-menu-right" role="menu">
          <li>
            <a
              @click.prevent="handleMergeButtonClick(true)"
              class="merge_when_pipeline_succeeds" href="#">
              <i class="fa fa-check fa-fw" aria-hidden="true"></i> Merge when pipeline succeeds
            </a>
          </li>
          <li>
            <a
              @click.prevent="handleMergeButtonClick(false)"
              class="accept-merge-request" href="#">
              <i class="fa fa-warning fa-fw" aria-hidden="true"></i> Merge immediately
            </a>
          </li>
        </ul>
      </span>
      <template v-if="isMergeAllowed()">
        <label class="spacing">
          <input type="checkbox" v-model="removeSourceBranch" /> Remove source branch
        </label>
        <a
          @click.prevent="toggleCommitMessageEditor"
          class="btn btn-default btn-xs" href="#">Modify commit message</a>
        <div class="prepend-top-default commit-message-editor" v-if="showCommitMessageEditor">
          <div class="form-group clearfix">
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
      </template>
      <template v-else>
        <span class="bold">
          The pipeline for this merge request failed. Please retry the job or push a new commit to fix the failure.
        </span>
      </template>
    </div>
  `,
};

import simplePoll from '~/lib/utils/simple_poll';
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
      isWorking: false,
      isMergingImmediately: false,
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
      if (this.isMergingImmediately) {
        return 'Merge in progress';
      } else if (this.mr.isPipelineActive) {
        return 'Merge when pipeline succeeds';
      }

      return 'Merge';
    },
    shouldShowMergeOptionsDropdown() {
      return this.mr.isPipelineActive && !this.mr.onlyAllowMergeIfPipelineSucceeds;
    },
    isMergeButtonDisabled() {
      const { commitMessage } = this;
      return !commitMessage.length || !this.isMergeAllowed() || this.isWorking;
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
    handleMergeButtonClick(mergeWhenBuildSucceeds, mergeImmediately) {
      // TODO: Remove no-param-reassign
      if (mergeWhenBuildSucceeds === undefined) {
        mergeWhenBuildSucceeds = this.mr.isPipelineActive; // eslint-disable-line no-param-reassign
      } else if (mergeImmediately) {
        this.isMergingImmediately = true;
      }

      this.setToMergeWhenPipelineSucceeds = mergeWhenBuildSucceeds === true;

      const options = {
        sha: this.mr.sha,
        commit_message: this.commitMessage,
        merge_when_pipeline_succeeds: this.setToMergeWhenPipelineSucceeds,
        should_remove_source_branch: this.removeSourceBranch === true,
      };

      this.isWorking = true;

      // TODO: Error handling
      this.service.merge(options)
        .then(res => res.json())
        .then((res) => {
          if (res.status === 'merge_when_pipeline_succeeds') {
            eventHub.$emit('MRWidgetUpdateRequested');
          } else if (res.status === 'success') {
            this.initiateMergePolling();
          } else if (res.status === 'failed') {
            eventHub.$emit('FailedToMerge');
          }
        });
    },
    initiateMergePolling() {
      simplePoll((continuePolling, stopPolling) => {
        this.service.pollResource.get()
          .then(res => res.json())
          .then((res) => {
            if (res.state === 'merged') {
              // If state is merged we should update the widget and stop the polling
              eventHub.$emit('MRWidgetUpdateRequested');
              stopPolling();

              // If user checked remove source branch and we didn't remove the branch yet
              // we should start another polling for source branch remove process
              if (this.removeSourceBranch && res.source_branch_exists) {
                this.initiateRemoveSourceBranchPolling();
              }
            } else {
              // MR is not merged yet, continue polling until the state becomes 'merged'
              continuePolling();
            }
          });
      });
    },
    initiateRemoveSourceBranchPolling() {
      // We need to show source branch is being removed spinner in another component
      eventHub.$emit('SetBranchRemoveFlag', [true]);

      simplePoll((continuePolling, stopPolling) => {
        this.service.pollResource.get()
          .then(res => res.json())
          .then((res) => {
            // If source branch exists then we should continue polling
            // because removing a source branch is a background task and takes time
            if (res.source_branch_exists) {
              continuePolling();
            } else {
              // Branch is removed. Update widget, stop polling and hide the spinner
              eventHub.$emit('MRWidgetUpdateRequested', () => {
                eventHub.$emit('SetBranchRemoveFlag', [false]);
              });
              stopPolling();
            }
          });
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
          type="button">
          <i
            v-if="isWorking"
            class="fa fa-spinner fa-spin"
            aria-hidden="true"></i>
          {{mergeButtonText}}
        </button>
        <button
          v-if="shouldShowMergeOptionsDropdown"
          :disabled="isMergeButtonDisabled"
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
              @click.prevent="handleMergeButtonClick(false, true)"
              class="accept-merge-request" href="#">
              <i class="fa fa-exclamation fa-fw" aria-hidden="true"></i> Merge immediately
            </a>
          </li>
        </ul>
      </span>
      <template v-if="isMergeAllowed()">
        <label class="spacing">
          <input
            v-model="removeSourceBranch"
            :disabled="isMergeButtonDisabled"
            type="checkbox"  /> Remove source branch
        </label>
        <a
          @click.prevent="toggleCommitMessageEditor"
          :disabled="isMergeButtonDisabled"
          class="btn btn-default btn-xs"
          href="#">Modify commit message</a>
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

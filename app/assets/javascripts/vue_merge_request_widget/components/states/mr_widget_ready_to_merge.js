export default {
  name: 'MRWidgetReadyToMerge',
  props: {
    mr: { type: Object, required: true, default: () => ({}) },
  },
  data() {
    return {
      removeSourceBranch: false,
      mergeWhenBuildSucceeds: false,
      useCommitMessageWithDescription: false,
      showCommitMessageEditor: false,
    };
  },
  computed: {
    commitMessage() {
      const cmwd = this.mr.commitMessageWithDescription;
      return this.useCommitMessageWithDescription ? cmwd : this.mr.commitMessage;
    },
    commitMessageLinkTitle() {
      const withDesc = 'Include description in commit message';
      const withoutDesc = "Don't include description in commit message";

      return this.useCommitMessageWithDescription ? withoutDesc : withDesc;
    },
  },
  methods: {
    toggleCommitMessageDescription() {
      this.useCommitMessageWithDescription = !this.useCommitMessageWithDescription;
    },
    toggleCommitMessageEditor() {
      this.showCommitMessageEditor = !this.showCommitMessageEditor;
    },
  },
  template: `
    <div class="mr-widget-body">
      <button class="btn btn-success btn-small">Merge</button>
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
              <a @click.prevent="toggleCommitMessageDescription" href="#">{{commitMessageLinkTitle}}</a>
            </div>
          </div>
        </div>
      </div>
      <input type="hidden" v-model="mergeWhenBuildSucceeds" />
    </div>
  `,
};

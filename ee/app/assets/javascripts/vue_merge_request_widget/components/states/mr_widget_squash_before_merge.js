import eventHub from '~/vue_merge_request_widget/event_hub';
import CESquashBeforeMerge from '~/vue_merge_request_widget/components/states/mr_widget_squash_before_merge';

export default {
  extends: CESquashBeforeMerge,
  props: {
    mr: {
      type: Object,
      required: true,
    },
    isMergeButtonDisabled: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      squashBeforeMerge: this.mr.squash,
    };
  },
  methods: {
    updateSquashModel() {
      eventHub.$emit('MRWidgetUpdateSquash', this.squashBeforeMerge);
    },
  },
  template: `
    <div class="accept-control inline">
      <label class="merge-param-checkbox">
        <input
          type="checkbox"
          name="squash"
          class="qa-squash-checkbox"
          :disabled="isMergeButtonDisabled"
          v-model="squashBeforeMerge"
          @change="updateSquashModel"/>
        Squash commits
      </label>
      <a
        :href="mr.squashBeforeMergeHelpPath"
        data-title="About this feature"
        data-toggle="tooltip"
        data-placement="bottom"
        target="_blank"
        rel="noopener noreferrer nofollow"
        data-container="body">
        <i
          class="fa fa-question-circle"
          aria-hidden="true"></i>
      </a>
    </div>`,
};

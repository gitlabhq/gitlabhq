import eventHub from '~/vue_merge_request_widget/event_hub';
import ReadyToMergeState from '~/vue_merge_request_widget/components/states/ready_to_merge.vue';
import SquashBeforeMerge from './mr_widget_squash_before_merge';

export default {
  extends: ReadyToMergeState,
  name: 'ReadyToMerge',
  components: {
    'squash-before-merge': SquashBeforeMerge,
  },
  data() {
    return {
      additionalParams: {
        squash: this.mr.squash,
      },
    };
  },
  methods: {
    // called in CE super component before form submission
    setAdditionalParams(options) {
      if (this.additionalParams) {
        Object.assign(options, this.additionalParams);
      }
    },
  },
  created() {
    eventHub.$on('MRWidgetUpdateSquash', (val) => {
      this.additionalParams.squash = val;
    });
  },
};

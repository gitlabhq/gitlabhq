import eventHub from '../../../event_hub';
import ReadyToMergeState from '../../../components/states/mr_widget_ready_to_merge';
import SquashBeforeMerge from './mr_widget_squash_before_merge';

export default {
  extends: ReadyToMergeState,
  name: 'MRWidgetReadyToMerge',
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

import { sprintf, s__ } from '../../../locale';

export default {
  name: 'time-tracking-help-state',
  props: {
    rootPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    href() {
      return `${this.rootPath}help/workflow/time_tracking.md`;
    },
    estimateText() {
      return sprintf(
        s__('estimateCommand|%{slash_command} will update the estimated time with the latest command.'), {
          slash_command: '<code>/estimate</code>',
        }, false,
      );
    },
    spendText() {
      return sprintf(
        s__('spendCommand|%{slash_command} will update the sum of the time spent.'), {
          slash_command: '<code>/spend</code>',
        }, false,
      );
    },
  },
  template: `
    <div class="time-tracking-help-state">
      <div class="time-tracking-info">
        <h4>
          {{ __('Track time with quick actions') }}
        </h4>
        <p>
          {{ __('Quick actions can be used in the issues description and comment boxes.') }}
        </p>
        <p v-html="estimateText">
        </p>
        <p v-html="spendText">
        </p>
        <a
          class="btn btn-default learn-more-button"
          :href="href"
        >
          {{ __('Learn more') }}
        </a>
      </div>
    </div>
  `,
};

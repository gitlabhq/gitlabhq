import { escape } from 'lodash';
import TruncatedText from './truncated_text.vue';

export default {
  component: TruncatedText,
  title: 'vue_shared/truncated_text',
};

const Template = (args, { argTypes }) => ({
  components: { TruncatedText },
  props: Object.keys(argTypes),
  template: `
  <truncated-text v-bind="$props">
    <template v-if="${'default' in args}" v-slot>
      <span style="white-space: pre-line;">${escape(args.default)}</span>
    </template>
  </truncated-text>
  `,
});

export const Default = Template.bind({});
Default.args = {
  lines: 3,
  mobileLines: 10,
  default: [...Array(15)].map((_, i) => `line ${i + 1}`).join('\n'),
};

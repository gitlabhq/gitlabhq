import ThResizable from './th_resizable.vue';

export default {
  component: ThResizable,
  title: 'glql/components/common/th_resizable',
  argTypes: {
    // events
    resize: { action: 'resize' },
  },
};

// The component measures the closest ancestor `<table>` to size its drag handle,
// so it only renders meaningfully inside a real table.
const Template = (args, { argTypes }) => ({
  components: { ThResizable },
  props: Object.keys(argTypes),
  template: `<table class="gl-w-full gl-table">
    <thead>
      <tr>
        <th-resizable v-on="{ resize }">Title</th-resizable>
        <th-resizable v-on="{ resize }">Author</th-resizable>
        <th>State</th>
      </tr>
    </thead>
    <tbody>
      <tr><td>Issue 1</td><td>foobar</td><td>Open</td></tr>
      <tr><td>Issue 2</td><td>janedoe</td><td>Closed</td></tr>
    </tbody>
  </table>`,
});

export const Default = Template.bind({});

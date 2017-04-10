export default {
  name: 'XLSXTable',
  props: {
    sheet: {
      type: Object,
      required: true,
    },
  },
  template: `
    <table
      class="table">
      <thead>
        <tr>
          <th></th>
          <th
            v-for="name in sheet.columns">
            {{ name }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="(row, index) in sheet.rows">
          <th>
            {{ index + 1 }}
          </th>
          <td v-for="val in row">
            {{ val }}
          </td>
        </tr>
      </tbody>
    </table>
  `,
};

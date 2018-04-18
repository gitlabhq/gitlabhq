<script>
export default {
  props: {
    rows: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <tbody>
    <tr
      v-for="(row, index) of rows"
      :key="index"
    >
      <td>
        <strong>
          <a :href="row.userWebUrl">{{ row.fullname }}</a>
        </strong>
      </td>
      <td>{{ row.push }}</td>
      <td>{{ row.issuesCreated }}</td>
      <td>{{ row.issuesClosed }}</td>
      <td>{{ row.mergeRequestsCreated }}</td>
      <td>{{ row.mergeRequestsMerged }}</td>
      <td>{{ row.totalEvents }}</td>
    </tr>
  </tbody>
</template>

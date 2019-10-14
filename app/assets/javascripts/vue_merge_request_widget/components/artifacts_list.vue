<script>
import { GlLink } from '@gitlab/ui';

export default {
  components: {
    GlLink,
  },
  props: {
    artifacts: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <table class="table m-0">
    <thead class="thead-white text-nowrap">
      <tr class="d-none d-sm-table-row">
        <th class="w-0"></th>
        <th>{{ __('Artifact') }}</th>
        <th class="w-50"></th>
        <th>{{ __('Job') }}</th>
      </tr>
    </thead>

    <tbody>
      <tr v-for="item in artifacts" :key="item.text">
        <td class="w-0"></td>
        <td>
          <gl-link :href="item.url" target="_blank">{{ item.text }}</gl-link>
        </td>
        <td class="w-0"></td>
        <td>
          <gl-link :href="item.job_path">{{ item.job_name }}</gl-link>
        </td>
      </tr>
    </tbody>
  </table>
</template>

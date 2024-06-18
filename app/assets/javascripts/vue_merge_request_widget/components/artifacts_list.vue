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
  <div class="gl-pl-7">
    <table class="table m-0">
      <thead class="thead-white text-nowrap">
        <tr class="gl-hidden sm:gl-table-row">
          <th>{{ __('Artifact') }}</th>
          <th>{{ __('Job') }}</th>
        </tr>
      </thead>

      <tbody>
        <tr v-for="item in artifacts" :key="item.text">
          <td>
            <gl-link :href="item.url" target="_blank">{{ item.text }}</gl-link>
          </td>
          <td>
            <gl-link :href="item.job_path">{{ item.job_name }}</gl-link>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
import ImportStatus from './import_status.vue';
import { STATUSES } from '../constants';

export default {
  name: 'ImportedProjectTableRow',
  components: {
    ImportStatus,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
  },

  computed: {
    displayFullPath() {
      return this.project.fullPath.replace(/^\//, '');
    },

    isFinished() {
      return this.project.importStatus === STATUSES.FINISHED;
    },
  },
};
</script>

<template>
  <tr class="js-imported-project import-row">
    <td>
      <a
        :href="project.providerLink"
        rel="noreferrer noopener"
        target="_blank"
        class="js-provider-link"
      >
        {{ project.importSource }}
      </a>
    </td>
    <td class="js-full-path">{{ displayFullPath }}</td>
    <td><import-status :status="project.importStatus" /></td>
    <td>
      <a
        v-if="isFinished"
        class="btn btn-default js-go-to-project"
        :href="project.fullPath"
        rel="noreferrer noopener"
        target="_blank"
      >
        {{ __('Go to project') }}
      </a>
    </td>
  </tr>
</template>

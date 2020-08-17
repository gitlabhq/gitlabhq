<script>
import { GlIcon } from '@gitlab/ui';
import ImportStatus from './import_status.vue';
import { STATUSES } from '../constants';

export default {
  name: 'ImportedProjectTableRow',
  components: {
    ImportStatus,
    GlIcon,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
  },

  computed: {
    displayFullPath() {
      return this.project.importedProject.fullPath.replace(/^\//, '');
    },

    isFinished() {
      return this.project.importStatus === STATUSES.FINISHED;
    },
  },
};
</script>

<template>
  <tr class="import-row">
    <td>
      <a
        :href="project.importSource.providerLink"
        rel="noreferrer noopener"
        target="_blank"
        data-testid="providerLink"
        >{{ project.importSource.fullName }}
        <gl-icon v-if="project.importSource.providerLink" name="external-link" />
      </a>
    </td>
    <td data-testid="fullPath">{{ displayFullPath }}</td>
    <td>
      <import-status :status="project.importStatus" />
    </td>
    <td>
      <a
        v-if="isFinished"
        class="btn btn-default"
        data-testid="goToProject"
        :href="project.importedProject.fullPath"
        rel="noreferrer noopener"
        target="_blank"
        >{{ __('Go to project') }}
      </a>
    </td>
  </tr>
</template>

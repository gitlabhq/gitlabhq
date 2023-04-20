<script>
import { GlButton } from '@gitlab/ui';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';
import { __ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';

export default {
  name: 'ExperimentHeader',
  components: {
    DeleteButton,
    GlButton,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    deleteInfo: {
      type: Object,
      required: true,
    },
  },
  methods: {
    downloadCsv() {
      const currentPath = window.location.pathname;
      const currentSearch = window.location.search;

      visitUrl(`${currentPath}.csv${currentSearch}`);
    },
  },
  i18n: {
    downloadAsCsvLabel: __('Download as CSV'),
  },
};
</script>

<template>
  <div class="detail-page-header gl-flex-wrap">
    <div class="detail-page-header-body">
      <h1 class="page-title gl-font-size-h-display flex-fill">{{ title }}</h1>

      <gl-button @click="downloadCsv">{{ $options.i18n.downloadAsCsvLabel }}</gl-button>

      <delete-button v-bind="deleteInfo" />
    </div>
  </div>
</template>

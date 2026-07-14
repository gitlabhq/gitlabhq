<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { mapState, mapActions } from 'pinia';
import { s__ } from '~/locale';
import { useMetricImages } from '~/vue_shared/components/metric_images/store';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import MetricImagesTable from '~/vue_shared/components/metric_images/metric_images_table.vue';
import MetricImageDetailsModal from './metric_image_details_modal.vue';

export default {
  name: 'MetricImagesTab',
  components: {
    GlLoadingIcon,
    MetricImagesTable,
    MetricImageDetailsModal,
    UploadDropzone,
  },
  inject: ['canUpdate', 'projectId', 'iid', 'metricImagesService'],
  data() {
    return {
      currentFiles: [],
      modalVisible: false,
    };
  },
  computed: {
    ...mapState(useMetricImages, ['metricImages', 'isLoadingMetricImages']),
  },
  mounted() {
    this.setInitialData({
      modelIid: this.iid,
      projectId: this.projectId,
      service: this.metricImagesService,
    });
    this.fetchImages();
  },
  methods: {
    ...mapActions(useMetricImages, ['fetchImages', 'setInitialData']),
    clearInputs() {
      this.modalVisible = false;
      this.currentFiles = [];
    },
    openMetricDialog(files) {
      this.modalVisible = true;
      this.currentFiles = files;
    },
  },
  i18n: {
    dropDescription: s__(
      'Incidents|Drop or %{linkStart}upload%{linkEnd} a metric screenshot to attach it to the incident',
    ),
  },
};
</script>

<template>
  <div>
    <div v-if="isLoadingMetricImages">
      <gl-loading-icon class="gl-p-5" size="sm" />
    </div>
    <metric-image-details-modal
      :image-files="currentFiles"
      :visible="modalVisible"
      @hidden="clearInputs"
    />
    <metric-images-table v-for="metric in metricImages" :key="metric.id" v-bind="metric" />
    <upload-dropzone
      v-if="canUpdate"
      :drop-description-message="$options.i18n.dropDescription"
      @change="openMetricDialog"
    />
  </div>
</template>

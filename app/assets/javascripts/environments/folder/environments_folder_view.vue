<script>
  import environmentsMixin from '../mixins/environments_mixin';
  import CIPaginationMixin from '../../vue_shared/mixins/ci_pagination_api_mixin';

  export default {
    mixins: [
      environmentsMixin,
      CIPaginationMixin,
    ],
    props: {
      endpoint: {
        type: String,
        required: true,
      },
      folderName: {
        type: String,
        required: true,
      },
      cssContainerClass: {
        type: String,
        required: true,
      },
      canCreateDeployment: {
        type: Boolean,
        required: true,
      },
      canReadEnvironment: {
        type: Boolean,
        required: true,
      },
    },
    methods: {
      successCallback(resp) {
        this.saveData(resp);
      },
    },
  };
</script>
<template>
  <div :class="cssContainerClass">
    <div
      class="top-area"
      v-if="!isLoading"
    >

      <h4 class="js-folder-name environments-folder-name">
        {{ s__("Environments|Environments") }} / <b>{{ folderName }}</b>
      </h4>

      <tabs
        :tabs="tabs"
        @onChangeTab="onChangeTab"
        scope="environments"
      />
    </div>

    <container
      :is-loading="isLoading"
      :environments="state.environments"
      :pagination="state.paginationInformation"
      :can-create-deployment="canCreateDeployment"
      :can-read-environment="canReadEnvironment"
      @onChangePage="onChangePage"
    />
  </div>
</template>

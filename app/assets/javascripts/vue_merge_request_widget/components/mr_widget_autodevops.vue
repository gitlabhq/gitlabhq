<script>
import _ from 'underscore';
import { s__, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'MRWidgetAutoDevops',
  components: {
    Icon,
  },
  props: {
    newCiConfig: {
      type: Boolean,
      required: true,
    },
    customCiConfigPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    warningMessage() {
      let warningMessage = '';
      if (this.customCiConfigPath !== '' && this.newCiConfig) {
        warningMessage = sprintf(
          s__(`mrWidget|This branch contains %{filename} which is being used as a custom CI config file.
      Merging will disable the Auto DevOps pipeline configuration for this project.`),
          {
            filename: `<code>${_.escape(this.customCiConfigPath)}</code>`,
          },
          false,
        );
      } else if (this.customCiConfigPath === '' && this.newCiConfig) {
        warningMessage = sprintf(
          s__(`mrWidget|This branch contains a %{gitlabCiYaml} file. 
      Merging will disable the Auto Devops pipeline configuration for this project.`),
          {
            gitlabCiYaml: '<code>gitlab-ci.yml</code>',
          },
          false,
        );
      }

      return warningMessage;
    },
  },
};
</script>
<template>
  <div class="mr-widget-heading">
    <div class="ci-widget media">
      <div class="ci-status-icon ci-status-icon-warning js-ci-status-icon-warning append-right-10">
        <icon name="status_warning" />
      </div>
      <div
        class="media-body"
        v-html="warningMessage">
      </div>
    </div>
  </div>
</template>

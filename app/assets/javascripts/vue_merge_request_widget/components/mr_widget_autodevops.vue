<script>
import { s__, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'MRWidgetAutoDevops',
  components: {
    Icon,
  },
  computed: {
    autoDevopsMsg() {
      return sprintf(s__(`mrWidget|This branch contains a %{gitlabCiYaml} file. 
      Merging will disable the Auto Devops pipeline configuration for this project`), {
        gitlabCiYaml: '<code>gitlab-ci.yml</code>',
      }, false);
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
        v-html="autoDevopsMsg">
      </div>
    </div>
  </div>
</template>

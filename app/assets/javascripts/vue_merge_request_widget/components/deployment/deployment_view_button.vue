<script>
import { GlLink } from '@gitlab/ui';
import FilteredSearchDropdown from '~/vue_shared/components/filtered_search_dropdown.vue';
import ReviewAppLink from '../review_app_link.vue';

export default {
  name: 'DeploymentViewButton',
  components: {
    FilteredSearchDropdown,
    GlLink,
    ReviewAppLink,
    VisualReviewAppLink: () =>
      import('ee_component/vue_merge_request_widget/components/visual_review_app_link.vue'),
  },
  props: {
    appButtonText: {
      type: Object,
      required: true,
    },
    deployment: {
      type: Object,
      required: true,
    },
    showVisualReviewApp: {
      type: Boolean,
      required: false,
      default: false,
    },
    visualReviewAppMeta: {
      type: Object,
      required: false,
      default: () => ({
        sourceProjectId: '',
        sourceProjectPath: '',
        mergeRequestId: '',
        appUrl: '',
      }),
    },
  },
  computed: {
    deploymentExternalUrl() {
      if (this.deployment.changes && this.deployment.changes.length === 1) {
        return this.deployment.changes[0].external_url;
      }
      return this.deployment.external_url;
    },
    shouldRenderDropdown() {
      return this.deployment.changes && this.deployment.changes.length > 1;
    },
  },
};
</script>

<template>
  <span>
    <filtered-search-dropdown
      v-if="shouldRenderDropdown"
      class="js-mr-wigdet-deployment-dropdown inline"
      :items="deployment.changes"
      :main-action-link="deploymentExternalUrl"
      filter-key="path"
    >
      <template slot="mainAction" slot-scope="slotProps">
        <review-app-link
          :display="appButtonText"
          :link="deploymentExternalUrl"
          :css-class="`deploy-link js-deploy-url inline ${slotProps.className}`"
        />
      </template>

      <template slot="result" slot-scope="slotProps">
        <gl-link
          :href="slotProps.result.external_url"
          target="_blank"
          rel="noopener noreferrer nofollow"
          class="js-deploy-url-menu-item menu-item"
        >
          <strong class="str-truncated-100 gl-mb-0 d-block">
            {{ slotProps.result.path }}
          </strong>

          <p class="text-secondary str-truncated-100 gl-mb-0 d-block">
            {{ slotProps.result.external_url }}
          </p>
        </gl-link>
      </template>
    </filtered-search-dropdown>
    <review-app-link
      v-else
      :display="appButtonText"
      :link="deploymentExternalUrl"
      css-class="js-deploy-url deploy-link btn btn-default btn-sm inline"
    />
    <visual-review-app-link
      v-if="showVisualReviewApp"
      :view-app-display="appButtonText"
      :link="deploymentExternalUrl"
      :app-metadata="visualReviewAppMeta"
      :changes="deployment.changes"
    />
  </span>
</template>

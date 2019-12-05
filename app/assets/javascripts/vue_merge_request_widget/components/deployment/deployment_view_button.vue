<script>
import FilteredSearchDropdown from '~/vue_shared/components/filtered_search_dropdown.vue';
import ReviewAppLink from '../review_app_link.vue';

export default {
  name: 'DeploymentViewButton',
  components: {
    FilteredSearchDropdown,
    ReviewAppLink,
    VisualReviewAppLink: () =>
      import('ee_component/vue_merge_request_widget/components/visual_review_app_link.vue'),
  },
  props: {
    deployment: {
      type: Object,
      required: true,
    },
    isCurrent: {
      type: Boolean,
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
          :is-current="isCurrent"
          :link="deploymentExternalUrl"
          :css-class="`deploy-link js-deploy-url inline ${slotProps.className}`"
        />
      </template>

      <template slot="result" slot-scope="slotProps">
        <a
          :href="slotProps.result.external_url"
          target="_blank"
          rel="noopener noreferrer nofollow"
          class="js-deploy-url-menu-item menu-item"
        >
          <strong class="str-truncated-100 append-bottom-0 d-block">
            {{ slotProps.result.path }}
          </strong>

          <p class="text-secondary str-truncated-100 append-bottom-0 d-block">
            {{ slotProps.result.external_url }}
          </p>
        </a>
      </template>
    </filtered-search-dropdown>
    <template v-else>
      <review-app-link
        :is-current="isCurrent"
        :link="deploymentExternalUrl"
        css-class="js-deploy-url deploy-link btn btn-default btn-sm inline"
      />
    </template>
    <visual-review-app-link
      v-if="showVisualReviewApp"
      :link="deploymentExternalUrl"
      :app-metadata="visualReviewAppMeta"
    />
  </span>
</template>

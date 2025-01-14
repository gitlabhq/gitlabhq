<script>
import { GlButtonGroup, GlCollapsibleListbox, GlLink } from '@gitlab/ui';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import ReviewAppLink from '../review_app_link.vue';

export default {
  name: 'DeploymentViewButton',
  components: {
    GlButtonGroup,
    GlCollapsibleListbox,
    GlLink,
    ReviewAppLink,
  },
  directives: {
    autofocusonshow,
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
  },
  data() {
    return { searchTerm: '' };
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
    filteredChanges() {
      return this.deployment?.changes
        ?.filter((change) => change.path.includes(this.searchTerm))
        .map((change) => ({ value: change.external_url, text: change.path }));
    },
  },
  methods: {
    search(searchTerm) {
      this.searchTerm = searchTerm;
    },
  },
};
</script>
<template>
  <span class="gl-inline-flex">
    <gl-button-group v-if="shouldRenderDropdown">
      <review-app-link
        :display="appButtonText"
        :link="deploymentExternalUrl"
        size="small"
        css-class="deploy-link js-deploy-url"
      />
      <gl-collapsible-listbox
        :items="filteredChanges"
        size="small"
        placement="bottom-end"
        searchable
        @search="search"
      >
        <template #list-item="{ item }">
          <gl-link :href="item.value" target="_blank" rel="noopener noreferrer nofollow">
            <div>
              <strong class="gl-mb-0 gl-block gl-truncate">{{ item.text }}</strong>
              <p class="gl-mb-0 gl-block gl-truncate gl-text-subtle">
                {{ item.value }}
              </p>
            </div>
          </gl-link>
        </template>
      </gl-collapsible-listbox>
    </gl-button-group>
    <review-app-link
      v-else
      :display="appButtonText"
      :link="deploymentExternalUrl"
      size="small"
      css-class="deploy-link js-deploy-url"
    />
  </span>
</template>

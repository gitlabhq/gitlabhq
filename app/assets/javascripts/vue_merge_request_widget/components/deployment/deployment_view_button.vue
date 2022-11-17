<script>
import {
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlIcon,
  GlLink,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { isSafeURL } from '~/lib/utils/url_utility';
import { s__, __ } from '~/locale';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import ReviewAppLink from '../review_app_link.vue';

export default {
  name: 'DeploymentViewButton',
  components: {
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlIcon,
    GlLink,
    GlSearchBoxByType,
    ModalCopyButton,
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
      return this.deployment?.changes?.filter((change) => change.path.includes(this.searchTerm));
    },
    isSafeUrl() {
      return isSafeURL(this.deploymentExternalUrl);
    },
  },
  i18n: {
    copy: __('Copy URL'),
    copyTitle: s__('Environments|Copy live environment URL'),
  },
};
</script>
<template>
  <span class="gl-display-inline-flex">
    <gl-button-group v-if="shouldRenderDropdown" size="small">
      <review-app-link
        v-if="isSafeUrl"
        :display="appButtonText"
        :link="deploymentExternalUrl"
        size="small"
        css-class="deploy-link js-deploy-url inline"
      />
      <modal-copy-button
        v-else
        :title="$options.i18n.copyTitle"
        :text="deploymentExternalUrl"
        size="small"
      >
        {{ $options.i18n.copy }}
      </modal-copy-button>
      <gl-dropdown toggle-class="gl-px-2!" size="small" class="js-mr-wigdet-deployment-dropdown">
        <template #button-content>
          <gl-icon
            class="dropdown-chevron gl-mx-0!"
            name="chevron-down"
            data-testid="mr-wigdet-deployment-dropdown-icon"
          />
        </template>
        <gl-search-box-by-type v-model.trim="searchTerm" v-autofocusonshow autofocus />
        <gl-dropdown-item
          v-for="change in filteredChanges"
          :key="change.path"
          class="js-filtered-dropdown-result"
        >
          <gl-link
            :href="change.external_url"
            target="_blank"
            rel="noopener noreferrer nofollow"
            class="js-deploy-url-menu-item menu-item"
          >
            <strong class="str-truncated-100 gl-mb-0 gl-display-block">{{ change.path }}</strong>
            <p class="text-secondary str-truncated-100 gl-mb-0 d-block">
              {{ change.external_url }}
            </p>
          </gl-link>
        </gl-dropdown-item>
      </gl-dropdown>
    </gl-button-group>
    <template v-else>
      <review-app-link
        v-if="isSafeUrl"
        :display="appButtonText"
        :link="deploymentExternalUrl"
        size="small"
        css-class="deploy-link js-deploy-url inline"
      />
      <modal-copy-button
        v-else
        :title="$options.i18n.copyTitle"
        :text="deploymentExternalUrl"
        size="small"
      >
        {{ $options.i18n.copy }}
      </modal-copy-button>
    </template>
  </span>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import store from '../stores';
import CollapsibleContainer from './collapsible_container.vue';
import ProjectEmptyState from './project_empty_state.vue';
import GroupEmptyState from './group_empty_state.vue';
import { s__, sprintf } from '~/locale';

export default {
  name: 'RegistryListApp',
  components: {
    CollapsibleContainer,
    GlEmptyState,
    GlLoadingIcon,
    ProjectEmptyState,
    GroupEmptyState,
  },
  props: {
    characterError: {
      type: Boolean,
      required: false,
      default: false,
    },
    containersErrorImage: {
      type: String,
      required: true,
    },
    endpoint: {
      type: String,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
    noContainersImage: {
      type: String,
      required: true,
    },
    personalAccessTokensHelpLink: {
      type: String,
      required: false,
      default: null,
    },
    registryHostUrlWithPort: {
      type: String,
      required: false,
      default: null,
    },
    repositoryUrl: {
      type: String,
      required: true,
    },
    isGroupPage: {
      type: Boolean,
      default: false,
      required: false,
    },
    twoFactorAuthHelpLink: {
      type: String,
      required: false,
      default: null,
    },
  },
  store,
  computed: {
    ...mapGetters(['isLoading', 'repos']),
    dockerConnectionErrorText() {
      return sprintf(
        s__(`ContainerRegistry|We are having trouble connecting to Docker, which could be due to an
            issue with your project name or path.
            %{docLinkStart}More Information%{docLinkEnd}`),
        {
          docLinkStart: `<a href="${this.helpPagePath}#docker-connection-error" target="_blank">`,
          docLinkEnd: '</a>',
        },
        false,
      );
    },
    introText() {
      return sprintf(
        s__(`ContainerRegistry|With the Docker Container Registry integrated into GitLab, every
            project can have its own space to store its Docker images.
            %{docLinkStart}More Information%{docLinkEnd}`),
        {
          docLinkStart: `<a href="${this.helpPagePath}" target="_blank">`,
          docLinkEnd: '</a>',
        },
        false,
      );
    },
    noContainerImagesText() {
      return sprintf(
        s__(`ContainerRegistry|With the Container Registry, every project can have its own space to
            store its Docker images. %{docLinkStart}More Information%{docLinkEnd}`),
        {
          docLinkStart: `<a href="${this.helpPagePath}" target="_blank">`,
          docLinkEnd: '</a>',
        },
        false,
      );
    },
  },
  created() {
    this.setMainEndpoint(this.endpoint);
    this.setIsDeleteDisabled(this.isGroupPage);
  },
  mounted() {
    if (!this.characterError) {
      this.fetchRepos();
    }
  },
  methods: {
    ...mapActions(['setMainEndpoint', 'fetchRepos', 'setIsDeleteDisabled']),
  },
};
</script>
<template>
  <div>
    <gl-empty-state
      v-if="characterError"
      :title="s__('ContainerRegistry|Docker connection error')"
      :svg-path="containersErrorImage"
    >
      <template #description>
        <p class="js-character-error-text" v-html="dockerConnectionErrorText"></p>
      </template>
    </gl-empty-state>

    <gl-loading-icon v-else-if="isLoading" size="md" class="prepend-top-16" />

    <div v-else-if="!isLoading && repos.length">
      <h4>{{ s__('ContainerRegistry|Container Registry') }}</h4>
      <p v-html="introText"></p>
      <collapsible-container v-for="item in repos" :key="item.id" :repo="item" />
    </div>
    <project-empty-state
      v-else-if="!isGroupPage"
      :no-containers-image="noContainersImage"
      :help-page-path="helpPagePath"
      :repository-url="repositoryUrl"
      :two-factor-auth-help-link="twoFactorAuthHelpLink"
      :personal-access-tokens-help-link="personalAccessTokensHelpLink"
      :registry-host-url-with-port="registryHostUrlWithPort"
    />
    <group-empty-state
      v-else-if="isGroupPage"
      :no-containers-image="noContainersImage"
      :help-page-path="helpPagePath"
    />
  </div>
</template>

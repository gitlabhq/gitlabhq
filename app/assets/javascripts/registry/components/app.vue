<script>
import { mapGetters, mapActions } from 'vuex';
import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import store from '../stores';
import clipboardButton from '../../vue_shared/components/clipboard_button.vue';
import CollapsibleContainer from './collapsible_container.vue';
import { s__, sprintf } from '../../locale';

export default {
  name: 'RegistryListApp',
  components: {
    clipboardButton,
    CollapsibleContainer,
    GlEmptyState,
    GlLoadingIcon,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    characterError: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
    noContainersImage: {
      type: String,
      required: true,
    },
    containersErrorImage: {
      type: String,
      required: true,
    },
    repositoryUrl: {
      type: String,
      required: true,
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
    dockerBuildCommand() {
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      return `docker build -t ${this.repositoryUrl} .`;
    },
    dockerPushCommand() {
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      return `docker push ${this.repositoryUrl}`;
    },
  },
  created() {
    this.setMainEndpoint(this.endpoint);
  },
  mounted() {
    if (!this.characterError) {
      this.fetchRepos();
    }
  },
  methods: {
    ...mapActions(['setMainEndpoint', 'fetchRepos']),
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
        <p v-html="dockerConnectionErrorText"></p>
      </template>
    </gl-empty-state>

    <gl-loading-icon v-else-if="isLoading" size="md" class="prepend-top-16" />

    <div v-else-if="!isLoading && repos.length">
      <h4>{{ s__('ContainerRegistry|Container Registry') }}</h4>
      <p v-html="introText"></p>
      <collapsible-container v-for="item in repos" :key="item.id" :repo="item" />
    </div>

    <gl-empty-state
      v-else
      :title="s__('ContainerRegistry|There are no container images stored for this project')"
      :svg-path="noContainersImage"
      class="container-message"
    >
      <template #description>
        <p class="js-no-container-images-text" v-html="noContainerImagesText"></p>
        <h5>{{ s__('ContainerRegistry|Quick Start') }}</h5>
        <p>
          {{
            s__(
              'ContainerRegistry|You can add an image to this registry with the following commands:',
            )
          }}
        </p>

        <div class="input-group append-bottom-10">
          <input :value="dockerBuildCommand" type="text" class="form-control monospace" readonly />
          <span class="input-group-append">
            <clipboard-button
              :text="dockerBuildCommand"
              :title="s__('ContainerRegistry|Copy build command to clipboard')"
              class="input-group-text"
            />
          </span>
        </div>

        <div class="input-group">
          <input :value="dockerPushCommand" type="text" class="form-control monospace" readonly />
          <span class="input-group-append">
            <clipboard-button
              :text="dockerPushCommand"
              :title="s__('ContainerRegistry|Copy push command to clipboard')"
              class="input-group-text"
            />
          </span>
        </div>
      </template>
    </gl-empty-state>
  </div>
</template>

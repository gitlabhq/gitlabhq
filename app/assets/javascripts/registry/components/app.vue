<script>
import { mapGetters, mapActions } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import store from '../stores';
import CollapsibleContainer from './collapsible_container.vue';
import SvgMessage from './svg_message.vue';
import { s__, sprintf } from '../../locale';

export default {
  name: 'RegistryListApp',
  components: {
    CollapsibleContainer,
    GlLoadingIcon,
    SvgMessage,
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
            issue with your project name or path. For more information, please review the
            %{docLinkStart}Container Registry documentation%{docLinkEnd}.`),
        {
          docLinkStart: `<a href="${this.helpPagePath}#docker-connection-error">`,
          docLinkEnd: '</a>',
        },
        false,
      );
    },
    introText() {
      return sprintf(
        s__(`ContainerRegistry|With the Docker Container Registry integrated into GitLab, every 
            project can have its own space to store its Docker images. Learn more about the 
            %{docLinkStart}Container Registry%{docLinkEnd}.`),
        {
          docLinkStart: `<a href="${this.helpPagePath}">`,
          docLinkEnd: '</a>',
        },
        false,
      );
    },
    noContainerImagesText() {
      return sprintf(
        s__(`ContainerRegistry|With the Container Registry, every project can have its own space to
            store its Docker images. Learn more about the %{docLinkStart}Container Registry%{docLinkEnd}.`),
        {
          docLinkStart: `<a href="${this.helpPagePath}">`,
          docLinkEnd: '</a>',
        },
        false,
      );
    },
  },
  created() {
    this.setMainEndpoint(this.endpoint);
  },
  mounted() {
    this.fetchRepos();
  },
  methods: {
    ...mapActions(['setMainEndpoint', 'fetchRepos']),
  },
};
</script>
<template>
  <div>
    <svg-message v-if="characterError" id="invalid-characters" :svg-path="containersErrorImage">
      <h4>
        {{ s__('ContainerRegistry|Docker connection error') }}
      </h4>
      <p v-html="dockerConnectionErrorText"></p>
    </svg-message>

    <gl-loading-icon v-else-if="isLoading" size="md" class="prepend-top-16" />

    <div v-else-if="!isLoading && !characterError && repos.length">
      <h4>{{ s__('ContainerRegistry|Container Registry') }}</h4>
      <p v-html="introText"></p>
      <collapsible-container v-for="item in repos" :key="item.id" :repo="item" />
    </div>

    <svg-message
      v-else-if="!isLoading && !characterError && !repos.length"
      id="no-container-images"
      :svg-path="noContainersImage"
    >
      <h4>
        {{ s__('ContainerRegistry|There are no container images stored for this project') }}
      </h4>
      <p v-html="noContainerImagesText"></p>

      <h5>{{ s__('ContainerRegistry|Quick Start') }}</h5>
      <p>
        {{
          s__(
            'ContainerRegistry|You can add an image to this registry with the following commands:',
          )
        }}
      </p>

      <pre>
        docker build -t {{ repositoryUrl }} .
        docker push {{ repositoryUrl }}
      </pre>
    </svg-message>
  </div>
</template>

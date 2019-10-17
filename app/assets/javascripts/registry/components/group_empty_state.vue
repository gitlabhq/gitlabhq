<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export default {
  name: 'GroupEmptyState',
  components: {
    GlEmptyState,
  },
  props: {
    noContainersImage: {
      type: String,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
  },
  computed: {
    noContainerImagesText() {
      return sprintf(
        s__(
          `ContainerRegistry|With the Container Registry, every project can have its own space to store its Docker images. Push at least one Docker image in one of this group's projects in order to show up here. %{docLinkStart}More Information%{docLinkEnd}`,
        ),
        {
          docLinkStart: `<a href="${this.helpPagePath}" target="_blank">`,
          docLinkEnd: '</a>',
        },
        false,
      );
    },
  },
};
</script>
<template>
  <gl-empty-state
    :title="s__('ContainerRegistry|There are no container images available in this group')"
    :svg-path="noContainersImage"
    class="container-message"
  >
    <template #description>
      <p class="js-no-container-images-text" v-html="noContainerImagesText"></p>
    </template>
  </gl-empty-state>
</template>

<script>
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'GroupEmptyState',
  components: {
    GlEmptyState,
    GlSprintf,
    GlLink,
  },
  inject: ['config'],
  containerRegistryHelpUrl: helpPagePath('user/packages/container_registry/_index'),
};
</script>
<template>
  <gl-empty-state
    :title="s__('ContainerRegistry|There are no container images available in this group')"
    :svg-path="config.noContainersImage"
    :svg-height="null"
  >
    <template #description>
      <p>
        <gl-sprintf
          :message="
            s__(
              `ContainerRegistry|With the Container Registry, every project can have its own space to store its Docker images. Push at least one Docker image in one of this group's projects in order to show up here. %{docLinkStart}More Information%{docLinkEnd}`,
            )
          "
        >
          <template #docLink="{ content }">
            <gl-link :href="$options.containerRegistryHelpUrl" target="_blank">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </template>
  </gl-empty-state>
</template>

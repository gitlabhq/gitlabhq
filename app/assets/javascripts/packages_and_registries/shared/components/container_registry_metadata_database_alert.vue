<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { getCookie, parseBoolean, setCookie } from '~/lib/utils/common_utils';
import { helpPagePath } from '~/helpers/help_page_helper';

const HIDE_METADATA_DATABASE_ALERT_COOKIE = 'hide_metadata_database_alert';

export default {
  name: 'ContainerRegistryMetadataDatabaseAlert',
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
  },
  data() {
    return {
      showAlert: !parseBoolean(getCookie(HIDE_METADATA_DATABASE_ALERT_COOKIE)),
    };
  },
  metadataDatabaseHelpPagePath: helpPagePath(
    'administration/packages/container_registry_metadata_database.md',
  ),
  methods: {
    hideAlert() {
      this.showAlert = false;
      setCookie(HIDE_METADATA_DATABASE_ALERT_COOKIE, 'true');
      this.$emit('dismiss');
    },
  },
};
</script>

<template>
  <gl-alert v-if="showAlert" class="gl-mt-5" @dismiss="hideAlert">
    <gl-sprintf
      :message="
        s__(
          'ContainerRegistry|The %{linkStart}next-generation container registry%{linkEnd} is now available for upgrade on self-managed instances. This upgraded registry supports online garbage collection, and has significant performance and reliability improvements.',
        )
      "
    >
      <template #link="{ content }">
        <gl-link :href="$options.metadataDatabaseHelpPagePath"> {{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>

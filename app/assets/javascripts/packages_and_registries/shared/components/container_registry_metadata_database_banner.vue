<script>
import PACKAGE_SVG from '@gitlab/svgs/dist/illustrations/cloud-check-sm.svg';
import { GlBanner } from '@gitlab/ui';
import { getCookie, parseBoolean, setCookie } from '~/lib/utils/common_utils';
import { helpPagePath } from '~/helpers/help_page_helper';

const HIDE_METADATA_DATABASE_ALERT_COOKIE = 'hide_metadata_database_alert';

export default {
  name: 'ContainerRegistryMetadataDatabaseBanner',
  components: {
    GlBanner,
  },
  data() {
    return {
      showBanner: !parseBoolean(getCookie(HIDE_METADATA_DATABASE_ALERT_COOKIE)),
    };
  },
  metadataDatabaseHelpPagePath: helpPagePath(
    'administration/packages/container_registry_metadata_database.md',
  ),
  computed: {
    buttonAttributes() {
      return { target: '_blank' };
    },
  },
  methods: {
    hideBanner() {
      this.showBanner = false;
      setCookie(HIDE_METADATA_DATABASE_ALERT_COOKIE, 'true');
      this.$emit('dismiss');
    },
  },
  PACKAGE_SVG,
};
</script>

<template>
  <gl-banner
    v-if="showBanner"
    :title="s__('ContainerRegistry|The next-generation container registry is now available')"
    class="gl-mt-5"
    :svg-path="$options.PACKAGE_SVG"
    :button-text="__('Learn more')"
    :button-link="$options.metadataDatabaseHelpPagePath"
    :button-attributes="buttonAttributes"
    @close="hideBanner"
  >
    <p>
      {{
        s__(
          'ContainerRegistry|Now available for upgrade on self-managed instances. This upgraded registry supports online garbage collection, and has significant performance and reliability improvements.',
        )
      }}
    </p>
  </gl-banner>
</template>

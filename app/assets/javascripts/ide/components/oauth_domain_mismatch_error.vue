<script>
import { GlButton, GlSprintf, GlCollapsibleListbox, GlIcon } from '@gitlab/ui';
import GITLAB_LOGO_SVG_URL from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg?url';
import { s__ } from '~/locale';
import { logError } from '~/lib/logger';

export default {
  name: 'OAuthDomainMismatchError',
  components: {
    GlButton,
    GlSprintf,
    GlCollapsibleListbox,
    GlIcon,
  },
  props: {
    callbackUrlOrigins: {
      type: Array,
      required: true,
    },
  },
  computed: {
    dropdownItems() {
      return this.callbackUrlOrigins.map((domain) => {
        return {
          value: domain,
          text: domain,
        };
      });
    },
  },
  methods: {
    reloadPage(urlDomain) {
      try {
        const current = new URL(urlDomain + window.location.pathname);
        window.location.replace(current.toString());
      } catch (e) {
        logError(s__('IDE|Error reloading page'), e);
      }
    },
  },
  gitlabLogo: GITLAB_LOGO_SVG_URL,
  i18n: {
    imgAlt: s__('IDE|GitLab logo'),
    buttonText: {
      singleDomain: s__('IDE|Reopen with %{domain}'),
      domains: s__('IDE|Reopen with other domain'),
    },
    dropdownHeader: s__('IDE|OAuth Callback URLs'),
    heading: s__('IDE|Cannot open Web IDE'),
    description: s__(
      "IDE|The URL you're using to access the Web IDE and the configured OAuth callback URL do not match. This issue often occurs when you're using a proxy.",
    ),
    contact: s__(
      'IDE|Contact your administrator or try to open the Web IDE again with another domain.',
    ),
  },
};
</script>
<template>
  <div class="gl-h-full flex gl-justify-center gl-items-center gl-p-4">
    <div class="text-center gl-max-w-75 gl-h-80">
      <img :alt="$options.i18n.imgAlt" :src="$options.gitlabLogo" class="svg gl-w-12 gl-h-12" />
      <h1 class="gl-heading-display gl-my-6">{{ $options.i18n.heading }}</h1>
      <p>
        {{ $options.i18n.description }}
      </p>
      <p>
        {{ $options.i18n.contact }}
      </p>
      <div class="gl-mt-6">
        <gl-collapsible-listbox
          v-if="callbackUrlOrigins.length > 1"
          :items="dropdownItems"
          :header-text="$options.i18n.dropdownHeader"
          @select="reloadPage"
        >
          <template #toggle>
            <gl-button variant="confirm" class="self-center">
              {{ $options.i18n.buttonText.domains }}
              <gl-icon class="dropdown-chevron gl-ml-2" name="chevron-down" />
            </gl-button>
          </template>
        </gl-collapsible-listbox>
        <gl-button v-else variant="confirm" @click="reloadPage(callbackUrlOrigins[0])">
          <gl-sprintf :message="$options.i18n.buttonText.singleDomain">
            <template #domain>
              {{ callbackUrlOrigins[0] }}
            </template>
          </gl-sprintf>
        </gl-button>
      </div>
    </div>
  </div>
</template>

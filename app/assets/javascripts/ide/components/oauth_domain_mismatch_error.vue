<script>
import { GlButton, GlLink, GlSprintf, GlDisclosureDropdown } from '@gitlab/ui';
import GITLAB_LOGO_SVG_URL from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg?url';
import { s__ } from '~/locale';
import { joinPaths, stripRelativeUrlRootFromPath } from '~/lib/utils/url_utility';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'OAuthDomainMismatchError',
  components: {
    GlButton,
    GlLink,
    GlSprintf,
    GlDisclosureDropdown,
  },
  props: {
    expectedCallbackUrl: {
      type: String,
      required: true,
    },
    callbackUrls: {
      type: Array,
      required: true,
    },
  },
  computed: {
    dropdownItems() {
      const currentOrigin = window.location.origin;

      return this.callbackUrls
        .filter(({ base }) => new URL(base).origin !== currentOrigin)
        .map(({ base }) => {
          return {
            href: joinPaths(base, stripRelativeUrlRootFromPath(window.location.pathname)),
            text: base,
          };
        });
    },
    helpPageUrl() {
      return helpPagePath('user/project/web_ide/_index', {
        anchor: 'update-the-oauth-callback-url',
      });
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
    expected: s__('IDE|Could not find a callback URL entry for %{expectedCallbackUrl}.'),
    contact: s__(
      'IDE|Contact your administrator or try to open the Web IDE again with another domain. %{linkStart}How can an administrator resolve the issue%{linkEnd}?',
    ),
  },
};
</script>
<template>
  <div class="overflow-auto gl-flex gl-h-full gl-items-center gl-justify-center">
    <div class="text-center gl-max-w-75 gl-p-4">
      <img :alt="$options.i18n.imgAlt" :src="$options.gitlabLogo" class="svg gl-h-12 gl-w-12" />
      <h1 class="gl-heading-display gl-my-6">{{ $options.i18n.heading }}</h1>
      <p>
        {{ $options.i18n.description }}
      </p>
      <p>
        <gl-sprintf :message="$options.i18n.expected">
          <template #expectedCallbackUrl>
            <code>{{ expectedCallbackUrl }}</code>
          </template>
        </gl-sprintf>
      </p>
      <p>
        <gl-sprintf :message="$options.i18n.contact">
          <template #link="{ content }">
            <gl-link :href="helpPageUrl">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
      <div class="gl-mt-6">
        <gl-disclosure-dropdown
          v-if="dropdownItems.length > 1"
          :items="dropdownItems"
          :toggle-text="$options.i18n.buttonText.domains"
        />
        <gl-button
          v-else-if="dropdownItems.length === 1"
          variant="confirm"
          :href="dropdownItems[0].href"
        >
          <gl-sprintf :message="$options.i18n.buttonText.singleDomain">
            <template #domain>
              {{ dropdownItems[0].text }}
            </template>
          </gl-sprintf>
        </gl-button>
      </div>
    </div>
  </div>
</template>

<script>
import { GlBanner } from '@gitlab/ui';
import { parseBoolean, getCookie, setCookie } from '~/lib/utils/common_utils';
import {
  INTRO_COOKIE_KEY,
  INTRO_BANNER_TITLE,
  INTRO_BANNER_BODY,
  INTRO_BANNER_ACTION_TEXT,
} from '../constants';

export default {
  name: 'DevopsScoreCallout',
  components: {
    GlBanner,
  },
  inject: {
    devopsReportDocsPath: {
      default: '',
    },
    devopsScoreIntroImagePath: {
      default: '',
    },
  },
  data() {
    return {
      bannerDismissed: parseBoolean(getCookie(INTRO_COOKIE_KEY)),
    };
  },
  i18n: {
    title: INTRO_BANNER_TITLE,
    body: INTRO_BANNER_BODY,
    action: INTRO_BANNER_ACTION_TEXT,
  },
  methods: {
    dismissBanner() {
      setCookie(INTRO_COOKIE_KEY, 'true');
      this.bannerDismissed = true;
    },
  },
};
</script>
<template>
  <gl-banner
    v-if="!bannerDismissed"
    class="gl-mt-3"
    variant="introduction"
    :title="$options.i18n.title"
    :button-text="$options.i18n.action"
    :button-link="devopsReportDocsPath"
    :svg-path="devopsScoreIntroImagePath"
    @close="dismissBanner"
  >
    <p>{{ $options.i18n.body }}</p>
  </gl-banner>
</template>

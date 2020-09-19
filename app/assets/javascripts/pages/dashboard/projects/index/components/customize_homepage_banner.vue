<script>
import { GlBanner } from '@gitlab/ui';
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import Tracking from '~/tracking';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlBanner,
  },
  mixins: [trackingMixin],
  inject: {
    svgPath: {
      default: '',
    },
    preferencesBehaviorPath: {
      default: '',
    },
    calloutsPath: {
      default: '',
    },
    calloutsFeatureId: {
      default: '',
    },
    trackLabel: {
      default: '',
    },
  },
  i18n: {
    title: s__('CustomizeHomepageBanner|Do you want to customize this page?'),
    body: s__(
      'CustomizeHomepageBanner|This page shows a list of your projects by default but it can be changed to show projects\' activity, groups, your to-do list, assigned issues, assigned merge requests, and more. You can change this under "Homepage content" in your preferences',
    ),
    button_text: s__('CustomizeHomepageBanner|Go to preferences'),
  },
  data() {
    return {
      visible: true,
      tracking: {
        label: this.trackLabel,
      },
    };
  },
  created() {
    this.$nextTick(() => {
      this.addTrackingAttributesToButton();
    });
  },
  mounted() {
    this.trackOnShow();
  },
  methods: {
    handleClose() {
      axios
        .post(this.calloutsPath, {
          feature_name: this.calloutsFeatureId,
        })
        .catch(e => {
          // eslint-disable-next-line @gitlab/require-i18n-strings, no-console
          console.error('Failed to dismiss banner.', e);
        });

      this.visible = false;
      this.track('click_dismiss');
    },
    trackOnShow() {
      if (this.visible) this.track('show_home_page_banner');
    },
    addTrackingAttributesToButton() {
      // we can't directly add these on the button like we need to due to
      // button not being modifiable currently
      // https://gitlab.com/gitlab-org/gitlab-ui/-/blob/9209ec424e5cca14bc8a1b5c9fa12636d8c83dad/src/components/base/banner/banner.vue#L60
      const button = this.$refs.banner.$el.querySelector(
        `[href='${this.preferencesBehaviorPath}']`,
      );

      if (button) {
        button.setAttribute('data-track-event', 'click_go_to_preferences');
        button.setAttribute('data-track-label', this.trackLabel);
      }
    },
  },
};
</script>

<template>
  <gl-banner
    v-if="visible"
    ref="banner"
    :title="$options.i18n.title"
    :button-text="$options.i18n.button_text"
    :button-link="preferencesBehaviorPath"
    :svg-path="svgPath"
    @close="handleClose"
  >
    <p>
      {{ $options.i18n.body }}
    </p>
  </gl-banner>
</template>

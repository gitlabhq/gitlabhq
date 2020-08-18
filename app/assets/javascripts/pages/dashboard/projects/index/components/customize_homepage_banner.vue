<script>
import { GlBanner } from '@gitlab/ui';
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';

export default {
  components: {
    GlBanner,
  },
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
    };
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
    },
  },
};
</script>

<template>
  <gl-banner
    v-if="visible"
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

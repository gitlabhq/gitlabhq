<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import Tracking from '~/tracking';
import {
  SP_TRACK_LABEL,
  SP_SHOW_TRACK_EVENT,
  SP_SHOW_TRACK_VALUE,
  SP_HELP_CONTENT,
  SP_ICON_NAME,
  SP_HELP_URL,
} from '../constants';
import MrWidgetIcon from './mr_widget_icon.vue';
import MrWidgetContainer from './mr_widget_container.vue';

const trackingMixin = Tracking.mixin();

export default {
  name: 'MRWidgetSuggestPipeline',
  SP_ICON_NAME,
  SP_TRACK_LABEL,
  SP_SHOW_TRACK_EVENT,
  SP_SHOW_TRACK_VALUE,
  SP_HELP_CONTENT,
  SP_HELP_URL,
  components: {
    GlLink,
    GlSprintf,
    MrWidgetIcon,
    MrWidgetContainer,
  },
  mixins: [trackingMixin],
  props: {
    humanAccess: {
      type: String,
      required: true,
    },
  },
  computed: {
    // eslint-disable-next-line vue/no-unused-properties -- `tracking` is used in the `Tracking` mixin.
    tracking() {
      return {
        label: SP_TRACK_LABEL,
        property: this.humanAccess,
      };
    },
  },
  mounted() {
    this.track();
  },
};
</script>
<template>
  <mr-widget-container>
    <div class="gl-flex">
      <mr-widget-icon :name="$options.SP_ICON_NAME" />
      <div>
        <div class="gl-my-2">
          <gl-sprintf
            :message="
              s__(`mrWidget|%{boldHeaderStart}Looks like there's no pipeline here.%{boldHeaderEnd}`)
            "
          >
            <template #boldHeader="{ content }">
              <strong>
                {{ content }}
              </strong>
            </template>
          </gl-sprintf>
        </div>
        <div>
          <gl-sprintf :message="$options.SP_HELP_CONTENT">
            <template #link="{ content }">
              <gl-link data-testid="help" :href="$options.SP_HELP_URL" target="_blank"
                >{{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </div>
      </div>
    </div>
  </mr-widget-container>
</template>

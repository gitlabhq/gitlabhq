<script>
import { GlAlert, GlLoadingIcon, GlSegmentedControl, GlToggle } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { STAGE_VIEW, LAYER_VIEW } from './constants';

export default {
  name: 'GraphViewSelector',
  components: {
    GlAlert,
    GlLoadingIcon,
    GlSegmentedControl,
    GlToggle,
  },
  props: {
    showLinks: {
      type: Boolean,
      required: true,
    },
    tipPreviouslyDismissed: {
      type: Boolean,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      hoverTipDismissed: false,
      isToggleLoading: false,
      isSwitcherLoading: false,
      segmentSelectedType: this.type,
      showLinksActive: false,
    };
  },
  i18n: {
    hoverTipText: __('Tip: Hover over a job to see the jobs it depends on to run.'),
    linksLabelText: s__('GraphViewType|Show dependencies'),
    viewLabelText: __('Group jobs by'),
  },
  views: {
    [STAGE_VIEW]: {
      type: STAGE_VIEW,
      text: {
        primary: s__('GraphViewType|Stage'),
      },
    },
    [LAYER_VIEW]: {
      type: LAYER_VIEW,
      text: {
        primary: s__('GraphViewType|Job dependencies'),
      },
    },
  },
  computed: {
    showLinksToggle() {
      return this.segmentSelectedType === LAYER_VIEW;
    },
    showTip() {
      return (
        this.showLinks &&
        this.showLinksActive &&
        !this.tipPreviouslyDismissed &&
        !this.hoverTipDismissed
      );
    },
    viewTypesList() {
      return Object.keys(this.$options.views).map((key) => {
        return {
          value: key,
          text: this.$options.views[key].text.primary,
        };
      });
    },
  },
  watch: {
    /*
      How does this reset the loading? As we note in the methods comment below,
      the loader is set to on before the update work is undertaken (in the parent).
      Once the work is complete, one of these values will change, since that's the
      point of the work. When that happens, the related value will update and we are done.

      The bonus for this approach is that it works the same whichever "direction"
      the work goes in.
    */
    showLinks() {
      this.isToggleLoading = false;
    },
    type() {
      this.isSwitcherLoading = false;
    },
  },
  methods: {
    dismissTip() {
      this.hoverTipDismissed = true;
      this.$emit('dismissHoverTip');
    },
    /*
      In both toggle methods, we use setTimeout so that the loading indicator displays,
      then the work is done to update the DOM. The process is:
        → user clicks
        → call stack: set loading to true
        → render: the loading icon appears on the screen
        → callback queue: now do the work to calculate the new view / links
          (note: this work is done in the parent after the event is emitted)

      setTimeout is how we move the work to the callback queue.
      We can't use nextTick because that is called before the render loop.

     See https://www.hesselinkwebdesign.nl/2019/nexttick-vs-settimeout-in-vue/ for more details.
    */
    toggleView(type) {
      this.isSwitcherLoading = true;
      setTimeout(() => {
        this.$emit('updateViewType', type);
      });
    },
    toggleShowLinksActive(val) {
      this.isToggleLoading = true;
      setTimeout(() => {
        this.$emit('updateShowLinksState', val);
      });
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-relative gl-display-flex gl-align-items-center gl-w-max-content gl-my-4">
      <gl-loading-icon
        v-if="isSwitcherLoading"
        data-testid="switcher-loading-state"
        class="gl-absolute gl-w-full gl-bg-white gl-opacity-5 gl-z-index-2"
        size="lg"
      />
      <span class="gl-font-weight-bold">{{ $options.i18n.viewLabelText }}</span>
      <gl-segmented-control
        v-model="segmentSelectedType"
        :options="viewTypesList"
        :disabled="isSwitcherLoading"
        data-testid="pipeline-view-selector"
        class="gl-mx-4"
        @input="toggleView"
      />

      <div v-if="showLinksToggle" class="gl-display-flex gl-align-items-center">
        <gl-toggle
          v-model="showLinksActive"
          data-testid="show-links-toggle"
          class="gl-mx-4"
          :label="$options.i18n.linksLabelText"
          :is-loading="isToggleLoading"
          label-position="left"
          @change="toggleShowLinksActive"
        />
      </div>
    </div>
    <gl-alert v-if="showTip" class="gl-my-5" variant="tip" @dismiss="dismissTip">
      {{ $options.i18n.hoverTipText }}
    </gl-alert>
  </div>
</template>

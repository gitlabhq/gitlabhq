import TooltipOnTruncate from './tooltip_on_truncate.vue';

const defaultWidth = '250px';

export default {
  component: TooltipOnTruncate,
  title: 'vue_shared/tooltip_on_truncate/tooltip_on_truncate.vue',
};

const createStory = ({ ...options }) => {
  return (_, { argTypes }) => {
    const comp = {
      components: { TooltipOnTruncate },
      props: Object.keys(argTypes),
      template: `
        <div class="gl-bg-blue-50" :style="{ width }">
          <tooltip-on-truncate :title="title" :placement="placement" class="gl-block gl-truncate">
            {{title}}
          </tooltip-on-truncate>
        </div>
      `,
      ...options,
    };

    return comp;
  };
};

export const Default = createStory();
Default.args = {
  width: defaultWidth,
  title: 'Hover on this text to see the content in a tooltip.',
};

export const NoOverflow = createStory();
NoOverflow.args = {
  width: defaultWidth,
  title: "Short text doesn't need a tooltip.",
};

export const Placement = createStory();
Placement.args = {
  width: defaultWidth,
  title: 'Use `placement="right"` to display this tooltip at the right.',
  placement: 'right',
};

const TIMEOUT_S = 3;

export const LiveUpdates = createStory({
  props: ['width', 'placement'],
  data() {
    return {
      title: `(loading in ${TIMEOUT_S}s)`,
    };
  },
  mounted() {
    setTimeout(() => {
      this.title = 'Content updated! The content is now overflowing so we use a tooltip!';
    }, TIMEOUT_S * 1000);
  },
});
LiveUpdates.args = {
  width: defaultWidth,
};
LiveUpdates.argTypes = {
  title: {
    control: false,
  },
};

export const TruncateTarget = createStory({
  template: `
    <div class="gl-bg-black" :style="{ width }">
      <tooltip-on-truncate class="gl-flex" :truncate-target="truncateTarget" :title="title">
        <div class="gl-m-5 gl-bg-blue-50 gl-truncate">
          {{ title }}
        </div>
      </tooltip-on-truncate>
    </div>
  `,
});
TruncateTarget.args = {
  width: defaultWidth,
  truncateTarget: 'child',
  title: 'Wrap in container and use `truncate-target="child"` prop.',
};

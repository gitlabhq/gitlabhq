// Stub for GitLab UI chart components: skips real ECharts rendering and
// exposes only the tooltip slots, driven by the given fixed params.
export const chartTooltipStub = (params) => ({
  template: `<div>
    <slot name="tooltip-title" :params="params"/>
    <slot name="tooltip-content" :params="params"/>
  </div>`,
  data: () => ({ params }),
});

export const GlLoadingIcon = { name: 'gl-loading-icon-stub', template: '<svg></svg>' };
export const GlCard = {
  name: 'gl-card-stub',
  template: `
<div>
  <slot name="header"></slot>
  <slot></slot>
  <slot name="footer"></slot>
</div>
`,
};

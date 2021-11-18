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

export const GlFormGroup = {
  name: 'gl-form-group-stub',
  props: ['state'],
  template: `
  <div>
    <slot name="label"></slot>
    <slot></slot>
    <slot name="description"></slot>
  </div>`,
};

export const GlFormSelect = {
  name: 'gl-form-select-stub',
  props: ['disabled', 'value'],
  template: `
  <div>
    <slot></slot>
  </div>`,
};

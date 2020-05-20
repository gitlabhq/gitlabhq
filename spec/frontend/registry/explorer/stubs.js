export const GlModal = {
  template: '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-ok"></slot></div>',
  methods: {
    show: jest.fn(),
  },
};

export const GlEmptyState = {
  template: '<div><slot name="description"></slot></div>',
  name: 'GlEmptyStateSTub',
};

export const RouterLink = {
  template: `<div><slot></slot></div>`,
  props: ['to'],
};

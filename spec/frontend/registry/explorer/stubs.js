import RealTagsTable from '~/registry/explorer/components/details_page/tags_table.vue';
import RealDeleteModal from '~/registry/explorer/components/details_page/delete_modal.vue';

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

export const TagsTable = {
  props: RealTagsTable.props,
  template: `<div><slot name="empty"></slot><slot name="loader"></slot></div>`,
};

export const DeleteModal = {
  template: '<div></div>',
  methods: {
    show: jest.fn(),
  },
  props: RealDeleteModal.props,
};

export const GlSkeletonLoader = {
  template: `<div><slot></slot></div>`,
  props: ['width', 'height'],
};

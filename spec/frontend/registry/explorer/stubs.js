import RealDeleteModal from '~/registry/explorer/components/details_page/delete_modal.vue';
import RealListItem from '~/vue_shared/components/registry/list_item.vue';

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

export const ListItem = {
  ...RealListItem,
  data() {
    return {
      detailsSlots: [],
      isDetailsShown: true,
    };
  },
};

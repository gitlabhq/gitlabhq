import {
  GlModal as RealGlModal,
  GlEmptyState as RealGlEmptyState,
  GlSkeletonLoader as RealGlSkeletonLoader,
} from '@gitlab/ui';
import { RouterLinkStub } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import RealDeleteModal from '~/registry/explorer/components/details_page/delete_modal.vue';
import RealListItem from '~/vue_shared/components/registry/list_item.vue';

export const GlModal = stubComponent(RealGlModal, {
  template: '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-ok"></slot></div>',
  methods: {
    show: jest.fn(),
  },
});

export const GlEmptyState = stubComponent(RealGlEmptyState, {
  template: '<div><slot name="description"></slot></div>',
});

export const RouterLink = RouterLinkStub;

export const DeleteModal = stubComponent(RealDeleteModal, {
  methods: {
    show: jest.fn(),
  },
});

export const GlSkeletonLoader = stubComponent(RealGlSkeletonLoader);

export const ListItem = {
  ...RealListItem,
  data() {
    return {
      detailsSlots: [],
      isDetailsShown: true,
    };
  },
};

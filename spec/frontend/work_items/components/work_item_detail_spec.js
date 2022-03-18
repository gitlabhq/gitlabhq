import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import WorkItemTitle from '~/work_items/components/item_title.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import { resolvers } from '~/work_items/graphql/resolvers';

describe('WorkItemDetailModal component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const findModal = () => wrapper.findComponent(GlModal);
  const findWorkItemTitle = () => wrapper.findComponent(WorkItemTitle);

  const createComponent = () => {
    wrapper = shallowMount(WorkItemDetailModal, {
      apolloProvider: createMockApollo([], resolvers),
      propsData: { visible: true },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders modal', () => {
    createComponent();

    expect(findModal().props()).toMatchObject({ visible: true });
  });

  it('renders work item title', () => {
    createComponent();

    expect(findWorkItemTitle().exists()).toBe(true);
  });
});

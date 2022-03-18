import { GlModal, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemTitle from '~/work_items/components/item_title.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import { workItemQueryResponse } from '../mock_data';

describe('WorkItemDetailModal component', () => {
  let wrapper;

  Vue.use(VueApollo);
  const successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);

  const findModal = () => wrapper.findComponent(GlModal);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findWorkItemTitle = () => wrapper.findComponent(WorkItemTitle);

  const createComponent = ({ workItemId = '1', handler = successHandler } = {}) => {
    wrapper = shallowMount(WorkItemDetailModal, {
      apolloProvider: createMockApollo([[workItemQuery, handler]]),
      propsData: { visible: true, workItemId },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders modal', () => {
    createComponent();

    expect(findModal().props()).toMatchObject({ visible: true });
  });

  describe('when there is no `workItemId` prop', () => {
    beforeEach(() => {
      createComponent({ workItemId: null });
    });

    it('renders empty title when there is no `workItemId` prop', () => {
      expect(findWorkItemTitle().exists()).toBe(true);
    });

    it('skips the work item query', () => {
      expect(successHandler).not.toHaveBeenCalled();
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render title', () => {
      expect(findWorkItemTitle().exists()).toBe(false);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('does not render loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders title', () => {
      expect(findWorkItemTitle().exists()).toBe(true);
    });
  });

  it('emits an error if query has errored', async () => {
    const errorHandler = jest.fn().mockRejectedValue('Oops');
    createComponent({ handler: errorHandler });

    expect(errorHandler).toHaveBeenCalled();
    await waitForPromises();
    expect(wrapper.emitted('error')).toEqual([
      ['Something went wrong when fetching the work item. Please try again.'],
    ]);
  });
});

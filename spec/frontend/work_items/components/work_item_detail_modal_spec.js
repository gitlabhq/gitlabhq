import { GlAlert, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import { i18n } from '~/work_items/constants';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import { workItemQueryResponse } from '../mock_data';

describe('WorkItemDetailModal component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const successHandler = jest.fn().mockResolvedValue({ data: workItemQueryResponse });

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findModal = () => wrapper.findComponent(GlModal);
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

    it('skips the work item query', () => {
      expect(successHandler).not.toHaveBeenCalled();
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders WorkItemTitle in loading state', () => {
      createComponent();

      expect(findWorkItemTitle().props('loading')).toBe(true);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('does not render WorkItemTitle in loading state', () => {
      expect(findWorkItemTitle().props('loading')).toBe(false);
    });
  });

  it('shows an error message when the work item query was unsuccessful', async () => {
    const errorHandler = jest.fn().mockRejectedValue('Oops');
    createComponent({ handler: errorHandler });
    await waitForPromises();

    expect(errorHandler).toHaveBeenCalled();
    expect(findAlert().text()).toBe(i18n.fetchError);
  });

  it('shows an error message when WorkItemTitle emits an `error` event', async () => {
    createComponent();

    findWorkItemTitle().vm.$emit('error', i18n.updateError);
    await waitForPromises();

    expect(findAlert().text()).toBe(i18n.updateError);
  });
});

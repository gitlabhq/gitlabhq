import Vue from 'vue';
import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import WorkItemsRoot from '~/work_items/pages/work_item_root.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import { i18n } from '~/work_items/constants';
import { workItemQueryResponse } from '../mock_data';

Vue.use(VueApollo);

const WORK_ITEM_ID = '1';

describe('Work items root component', () => {
  let wrapper;

  const successHandler = jest.fn().mockResolvedValue({ data: workItemQueryResponse });

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findWorkItemTitle = () => wrapper.findComponent(WorkItemTitle);

  const createComponent = ({ handler = successHandler } = {}) => {
    wrapper = shallowMount(WorkItemsRoot, {
      apolloProvider: createMockApollo([[workItemQuery, handler]]),
      propsData: {
        id: WORK_ITEM_ID,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
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

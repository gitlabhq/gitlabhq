import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SubscriptionsPage from '~/jira_connect/subscriptions/pages/subscriptions.vue';
import AddNamespaceButton from '~/jira_connect/subscriptions/components/add_namespace_button.vue';
import SubscriptionsList from '~/jira_connect/subscriptions/components/subscriptions_list.vue';
import createStore from '~/jira_connect/subscriptions/store';

describe('SubscriptionsPage', () => {
  let wrapper;
  let store;

  const findAddNamespaceButton = () => wrapper.findComponent(AddNamespaceButton);
  const findSubscriptionsList = () => wrapper.findComponent(SubscriptionsList);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const createComponent = ({ props } = {}) => {
    store = createStore();

    wrapper = shallowMount(SubscriptionsPage, {
      store,
      propsData: props,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    describe.each`
      scenario                   | expectSubscriptionsList | expectEmptyState
      ${'with subscriptions'}    | ${true}                 | ${false}
      ${'without subscriptions'} | ${false}                | ${true}
    `('$scenario', ({ expectEmptyState, expectSubscriptionsList }) => {
      beforeEach(() => {
        createComponent({
          props: {
            hasSubscriptions: expectSubscriptionsList,
          },
        });
      });

      it('renders button to add namespace', () => {
        expect(findAddNamespaceButton().exists()).toBe(true);
      });

      it(`${expectEmptyState ? 'renders' : 'does not render'} empty state`, () => {
        expect(findEmptyState().exists()).toBe(expectEmptyState);
      });

      it(`${expectSubscriptionsList ? 'renders' : 'does not render'} subscriptions list`, () => {
        expect(findSubscriptionsList().exists()).toBe(expectSubscriptionsList);
      });
    });
  });
});

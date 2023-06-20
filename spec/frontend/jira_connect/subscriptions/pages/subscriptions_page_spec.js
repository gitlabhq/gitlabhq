import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SubscriptionsPage from '~/jira_connect/subscriptions/pages/subscriptions_page.vue';
import AddNamespaceButton from '~/jira_connect/subscriptions/components/add_namespace_button.vue';
import SubscriptionsList from '~/jira_connect/subscriptions/components/subscriptions_list.vue';
import createStore from '~/jira_connect/subscriptions/store';

describe('SubscriptionsPage', () => {
  let wrapper;
  let store;

  const findAddNamespaceButton = () => wrapper.findComponent(AddNamespaceButton);
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findSubscriptionsList = () => wrapper.findComponent(SubscriptionsList);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const createComponent = ({ props, initialState } = {}) => {
    store = createStore(initialState);

    wrapper = shallowMount(SubscriptionsPage, {
      store,
      propsData: { hasSubscriptions: false, ...props },
      stubs: {
        GlEmptyState,
      },
    });
  };

  describe('template', () => {
    describe.each`
      scenario                        | subscriptionsLoading | hasSubscriptions | expectSubscriptionsList | expectEmptyState
      ${'with subscriptions loading'} | ${true}              | ${false}         | ${false}                | ${false}
      ${'with subscriptions'}         | ${false}             | ${true}          | ${true}                 | ${false}
      ${'without subscriptions'}      | ${false}             | ${false}         | ${false}                | ${true}
    `(
      '$scenario',
      ({ subscriptionsLoading, hasSubscriptions, expectEmptyState, expectSubscriptionsList }) => {
        beforeEach(() => {
          createComponent({
            initialState: { subscriptionsLoading },
            props: {
              hasSubscriptions,
            },
          });
        });

        it(`${subscriptionsLoading ? 'does not render' : 'renders'} button to add group`, () => {
          expect(findAddNamespaceButton().exists()).toBe(!subscriptionsLoading);
        });

        it(`${subscriptionsLoading ? 'renders' : 'does not render'} GlLoadingIcon`, () => {
          expect(findGlLoadingIcon().exists()).toBe(subscriptionsLoading);
        });

        it(`${expectEmptyState ? 'renders' : 'does not render'} empty state`, () => {
          expect(findEmptyState().exists()).toBe(expectEmptyState);
        });

        it(`${expectSubscriptionsList ? 'renders' : 'does not render'} subscriptions list`, () => {
          expect(findSubscriptionsList().exists()).toBe(expectSubscriptionsList);
        });
      },
    );
  });
});

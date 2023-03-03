import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import permissionsQuery from 'shared_queries/design_management/design_permissions.query.graphql';
import DeleteButton from '~/design_management/components/delete_button.vue';
import Toolbar from '~/design_management/components/toolbar/index.vue';
import { DESIGNS_ROUTE_NAME } from '~/design_management/router/constants';
import { getPermissionsQueryResponse } from '../../mock_data/apollo_mock';

Vue.use(VueRouter);
Vue.use(VueApollo);
const router = new VueRouter();

const RouterLinkStub = {
  props: {
    to: {
      type: Object,
    },
  },
  render(createElement) {
    return createElement('a', {}, this.$slots.default);
  },
};

describe('Design management toolbar component', () => {
  let wrapper;

  function createComponent(isLoading = false, createDesign = true, props) {
    const updatedAt = new Date();
    updatedAt.setHours(updatedAt.getHours() - 1);

    const mockApollo = createMockApollo([
      [permissionsQuery, jest.fn().mockResolvedValue(getPermissionsQueryResponse(createDesign))],
    ]);

    wrapper = shallowMount(Toolbar, {
      apolloProvider: mockApollo,
      router,
      propsData: {
        id: '1',
        isLatestVersion: true,
        isLoading,
        isDeleting: false,
        filename: 'test.jpg',
        updatedAt: updatedAt.toString(),
        updatedBy: {
          name: 'Test Name',
        },
        image: '/-/designs/306/7f747adcd4693afadbe968d7ba7d983349b9012d',
        ...props,
      },
      stubs: {
        'router-link': RouterLinkStub,
      },
    });
  }

  it('renders design and updated data', async () => {
    createComponent();

    await waitForPromises();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('links back to designs list', async () => {
    createComponent();

    await waitForPromises();
    const link = wrapper.find('a');

    expect(link.props('to')).toEqual({
      name: DESIGNS_ROUTE_NAME,
      query: {
        version: undefined,
      },
    });
  });

  it('renders delete button on latest designs version with logged in user', async () => {
    createComponent();

    await waitForPromises();

    expect(wrapper.findComponent(DeleteButton).exists()).toBe(true);
  });

  it('does not render delete button on non-latest version', async () => {
    createComponent(false, true, { isLatestVersion: false });

    await waitForPromises();

    expect(wrapper.findComponent(DeleteButton).exists()).toBe(false);
  });

  it('does not render delete button when user is not logged in', async () => {
    createComponent(false, false);

    await waitForPromises();

    expect(wrapper.findComponent(DeleteButton).exists()).toBe(false);
  });

  it('emits `delete` event on deleteButton `delete-selected-designs` event', async () => {
    createComponent();

    await waitForPromises();

    wrapper.findComponent(DeleteButton).vm.$emit('delete-selected-designs');
    expect(wrapper.emitted().delete).toHaveLength(1);
  });

  it('renders download button with correct link', async () => {
    createComponent();

    await waitForPromises();

    expect(wrapper.findComponent(GlButton).attributes('href')).toBe(
      '/-/designs/306/7f747adcd4693afadbe968d7ba7d983349b9012d',
    );
  });
});

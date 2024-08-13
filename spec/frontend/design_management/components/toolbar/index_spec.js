import { GlButton } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import permissionsQuery from 'shared_queries/design_management/design_permissions.query.graphql';
import DeleteButton from '~/design_management/components/delete_button.vue';
import DesignTodoButton from '~/design_management/components/design_todo_button.vue';
import Toolbar from '~/design_management/components/toolbar/index.vue';
import CloseButton from '~/design_management/components/toolbar/close_button.vue';
import { getPermissionsQueryResponse } from '../../mock_data/apollo_mock';
import design from '../../mock_data/design';

Vue.use(VueRouter);
Vue.use(VueApollo);
const router = new VueRouter();

describe('Design management toolbar component', () => {
  let wrapper;

  // eslint-disable-next-line max-params
  function createComponent(isLoading = false, createDesign = true, props, isLoggedIn = true) {
    if (isLoggedIn) {
      window.gon.current_user_id = 1;
    }

    const updatedAt = new Date();
    updatedAt.setHours(updatedAt.getHours() - 1);

    const mockApollo = createMockApollo([
      [permissionsQuery, jest.fn().mockResolvedValue(getPermissionsQueryResponse(createDesign))],
    ]);

    wrapper = shallowMountExtended(Toolbar, {
      apolloProvider: mockApollo,
      router,
      propsData: {
        id: '1',
        isLatestVersion: true,
        isLoading,
        isDeleting: false,
        design,
        filename: 'test.jpg',
        updatedAt: updatedAt.toString(),
        updatedBy: {
          name: 'Test Name',
        },
        image: '/-/designs/306/7f747adcd4693afadbe968d7ba7d983349b9012d',
        ...props,
      },
    });
  }

  it('renders design and updated data', async () => {
    createComponent();

    await waitForPromises();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders issue title', async () => {
    createComponent();

    await waitForPromises();

    expect(wrapper.find('h2').text()).toContain(design.issue.title);
  });

  it('renders close button', async () => {
    createComponent();

    await waitForPromises();
    expect(wrapper.findComponent(CloseButton).exists()).toBe(true);
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

  it('renders To-Do button', () => {
    createComponent();

    expect(wrapper.findComponent(DesignTodoButton).exists()).toBe(true);
  });

  it('does not render To-Do button when user is not logged in', async () => {
    createComponent(false, false, {}, false);

    await waitForPromises();

    expect(wrapper.findComponent(DesignTodoButton).exists()).toBe(false);
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

  it('emits toggle-sidebar event when clicking on toggle sidebar button', async () => {
    createComponent();

    wrapper.findByTestId('toggle-design-sidebar').vm.$emit('click');
    await nextTick();

    expect(wrapper.emitted('toggle-sidebar')).toHaveLength(1);
  });
});

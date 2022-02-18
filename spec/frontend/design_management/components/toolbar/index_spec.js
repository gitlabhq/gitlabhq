import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueRouter from 'vue-router';
import DeleteButton from '~/design_management/components/delete_button.vue';
import Toolbar from '~/design_management/components/toolbar/index.vue';
import { DESIGNS_ROUTE_NAME } from '~/design_management/router/constants';

Vue.use(VueRouter);
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

    wrapper = shallowMount(Toolbar, {
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

    // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
    // eslint-disable-next-line no-restricted-syntax
    wrapper.setData({
      permissions: {
        createDesign,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders design and updated data', async () => {
    createComponent();

    await nextTick();
    expect(wrapper.element).toMatchSnapshot();
  });

  it('links back to designs list', async () => {
    createComponent();

    await nextTick();
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

    await nextTick();
    expect(wrapper.find(DeleteButton).exists()).toBe(true);
  });

  it('does not render delete button on non-latest version', async () => {
    createComponent(false, true, { isLatestVersion: false });

    await nextTick();
    expect(wrapper.find(DeleteButton).exists()).toBe(false);
  });

  it('does not render delete button when user is not logged in', async () => {
    createComponent(false, false);

    await nextTick();
    expect(wrapper.find(DeleteButton).exists()).toBe(false);
  });

  it('emits `delete` event on deleteButton `delete-selected-designs` event', async () => {
    createComponent();

    await nextTick();
    wrapper.find(DeleteButton).vm.$emit('delete-selected-designs');
    expect(wrapper.emitted().delete).toBeTruthy();
  });

  it('renders download button with correct link', () => {
    createComponent();

    expect(wrapper.find(GlButton).attributes('href')).toBe(
      '/-/designs/306/7f747adcd4693afadbe968d7ba7d983349b9012d',
    );
  });
});

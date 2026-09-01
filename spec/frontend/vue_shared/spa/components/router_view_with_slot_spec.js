import Vue from 'vue';
import VueRouter from 'vue-router';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RouterViewWithSlot from '~/vue_shared/spa/components/router_view_with_slot';

Vue.use(VueRouter);

describe('RouterViewWithSlot', () => {
  const onFoo = jest.fn();

  const TestRouteComponent = {
    name: 'TestRouteComponent',
    emits: ['foo'],
    mounted() {
      this.$emit('foo', 'payload');
    },
    template: `
      <div class="route-content">
        <slot name="header"></slot>
        route content
      </div>
    `,
  };

  const TestApp = {
    name: 'TestApp',
    components: {
      RouterViewWithSlot,

      // @vue/test-utils only precompiles templates in a component's own `components`
      // option, so this must be listed here even though it's used only via vue-router.
      TestRouteComponent,
    },
    methods: { onFoo },
    template: `
      <router-view-with-slot #default="{ Component }">
        <component :is="Component" @foo="onFoo">
          <template #header>
            <div class="route-header">header content</div>
          </template>
        </component>
      </router-view-with-slot>
    `,
  };

  const mountTestApp = async () => {
    const router = new VueRouter({
      mode: 'abstract',
      routes: [{ path: '/', component: TestRouteComponent }],
    });
    router.push('/').catch(() => {});
    await waitForPromises();

    const wrapper = mountExtended(TestApp, { router });
    await waitForPromises();

    return wrapper;
  };

  const TestPropsRouteComponent = {
    name: 'TestPropsRouteComponent',
    props: {
      label: {
        type: String,
        required: true,
      },
    },
    template: `<div class="route-props">{{ label }}</div>`,
  };

  const TestAppWithRouteProps = {
    name: 'TestAppWithRouteProps',
    components: {
      RouterViewWithSlot,
      TestPropsRouteComponent,
    },
    template: `
      <router-view-with-slot #default="{ Component }">
        <component :is="Component" />
      </router-view-with-slot>
    `,
  };

  const TestAppWithRoutePropsOverride = {
    name: 'TestAppWithRoutePropsOverride',
    components: {
      RouterViewWithSlot,
      TestPropsRouteComponent,
    },
    template: `
      <router-view-with-slot #default="{ Component }">
        <component :is="Component" label="explicit" />
      </router-view-with-slot>
    `,
  };

  const mountWithRouteProps = async (rootComponent) => {
    const router = new VueRouter({
      mode: 'abstract',
      routes: [
        { path: '/', component: TestPropsRouteComponent, props: () => ({ label: 'from-route' }) },
      ],
    });
    router.push('/').catch(() => {});
    await waitForPromises();

    const wrapper = mountExtended(rootComponent, { router });
    await waitForPromises();

    return wrapper;
  };

  beforeEach(() => {
    onFoo.mockClear();
  });

  it('renders the matched component', async () => {
    const wrapper = await mountTestApp();

    expect(wrapper.find('.route-content').text()).toContain('route content');
  });

  it('forwards a listener bound on the unwrapped Component', async () => {
    await mountTestApp();

    expect(onFoo).toHaveBeenCalledWith('payload');
  });

  it('forwards a named slot bound on the unwrapped Component', async () => {
    const wrapper = await mountTestApp();

    expect(wrapper.find('.route-header').text()).toBe('header content');
  });

  it('merges the route config props into the unwrapped Component', async () => {
    const wrapper = await mountWithRouteProps(TestAppWithRouteProps);

    expect(wrapper.find('.route-props').text()).toBe('from-route');
  });

  it('lets an explicit prop on the unwrapped Component override the route config prop', async () => {
    const wrapper = await mountWithRouteProps(TestAppWithRoutePropsOverride);

    expect(wrapper.find('.route-props').text()).toBe('explicit');
  });
});

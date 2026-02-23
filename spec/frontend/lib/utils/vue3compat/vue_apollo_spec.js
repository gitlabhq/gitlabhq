import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';

Vue.use(VueApollo);

describe('$apollo availability in child components created via parent option', () => {
  it('child instance created with new Vue and parent option has $apollo', () => {
    const apolloProvider = createMockApollo([]);

    const parentApp = new Vue({
      el: document.createElement('div'),
      name: 'ParentApp',
      apolloProvider,
      render() {
        return null;
      },
    });

    expect(parentApp.$apollo).toBeDefined();

    let childApollo = null;

    // eslint-disable-next-line no-new
    new Vue({
      el: document.createElement('div'),
      name: 'ChildApp',
      parent: parentApp,
      mounted() {
        childApollo = this.$apollo;
      },
      render() {
        return null;
      },
    });

    expect(childApollo).toBeDefined();
    expect(typeof childApollo.mutate).toBe('function');
  });

  it('child $apollo remains usable after parent is destroyed', () => {
    const apolloProvider = createMockApollo([]);

    const wrapper = mount(
      {
        name: 'ParentWithApollo',
        template: '<div><ChildComp ref="child" /></div>',
        components: {
          ChildComp: {
            name: 'ChildComp',
            template: '<div></div>',
            methods: {
              getApollo() {
                return this.$apollo;
              },
            },
          },
        },
      },
      { apolloProvider },
    );

    const childVm = wrapper.findComponent({ name: 'ChildComp' }).vm;

    expect(childVm.getApollo()).toBeDefined();
    expect(typeof childVm.getApollo().mutate).toBe('function');

    wrapper.destroy();

    const apollo = childVm.getApollo();
    expect(apollo).toBeDefined();
    expect(typeof apollo.mutate).toBe('function');
  });
});

import { GlToast } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { createWrapper } from '@vue/test-utils';
import Vue, { defineComponent, h } from 'vue';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import createDefaultClient from '~/lib/graphql';

const MockComponent = defineComponent({
  name: 'MockComponent',
  props: {
    someKey: {
      type: String,
      required: false,
      default: '',
    },
    count: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  render: () => h('span'),
});

let wrapper;

const findMock = () => wrapper.findComponent(MockComponent);

const didCreateApp = () => wrapper !== undefined;

const initMock = (html, options = {}) => {
  setHTMLFixture(html);

  const app = initSimpleApp('#mount-here', MockComponent, options);

  wrapper = app ? createWrapper(app) : undefined;
};

describe('helpers/init_simple_app_helper/initSimpleApp', () => {
  afterEach(() => {
    resetHTMLFixture();
  });

  it('mounts the component if the selector exists', () => {
    initMock('<div id="mount-here"></div>');

    expect(findMock().exists()).toBe(true);
  });

  it('does not mount the component if selector does not exist', () => {
    initMock('<div id="do-not-mount-here"></div>');

    expect(didCreateApp()).toBe(false);
  });

  it('passes the prop to the component if the prop exists', () => {
    initMock(`<div id="mount-here" data-view-model={"someKey":"thing","count":123}></div>`);

    expect(findMock().props()).toEqual({
      someKey: 'thing',
      count: 123,
    });
  });

  it('passes the provide to the component if data-provide exists', () => {
    initMock(`<div id="mount-here" data-provide={"someKey":"thing","count":123}></div>`);

    expect(wrapper.vm.$options.provide).toEqual({
      someKey: 'thing',
      count: 123,
    });
  });

  describe('options', () => {
    describe('withApolloProvider', () => {
      describe('if false, does not add apollo', () => {
        it('apolloProvider not created', () => {
          initMock('<div id="mount-here"></div>', { withApolloProvider: false });

          expect(wrapper.vm.$apollo).toBeUndefined();
        });
      });

      describe('if true, sets up apollo', () => {
        it('creates a default apolloProvider', () => {
          initMock('<div id="mount-here"></div>', { withApolloProvider: true });

          expect(wrapper.vm.$apollo).not.toBeUndefined();
        });
      });

      describe('if custom apollo provider, sets up apollo', () => {
        it('uses apolloProvider', () => {
          const apolloProvider = new VueApollo({
            defaultClient: createDefaultClient(),
          });

          initMock('<div id="mount-here"></div>', { withApolloProvider: apolloProvider });

          expect(wrapper.vm.$apollo).not.toBeUndefined();
        });
      });
    });

    describe('name', () => {
      describe('if no name is given', () => {
        it('name is undefined', () => {
          initMock('<div id="mount-here"></div>');

          expect(wrapper.vm.$options.name).toBeUndefined();
        });
      });

      describe('if a name is given', () => {
        it('name is set to the given', () => {
          initMock('<div id="mount-here"></div>', { name: 'CoolAppRoot' });

          expect(wrapper.vm.$options.name).toBe('CoolAppRoot');
        });
      });
    });

    describe('withVueRouter', () => {
      let vueUseSpy;

      beforeEach(() => {
        vueUseSpy = jest.spyOn(Vue, 'use');
      });

      describe('if false (default), Vue Router is not registered', () => {
        it('does not call Vue.use with VueRouter', () => {
          initMock('<div id="mount-here"></div>');

          expect(vueUseSpy).not.toHaveBeenCalledWith(VueRouter);
        });
      });

      describe('if true, registers Vue Router', () => {
        it('calls Vue.use with VueRouter', () => {
          initMock('<div id="mount-here"></div>', { withVueRouter: true });

          expect(vueUseSpy).toHaveBeenCalledWith(VueRouter);
        });
      });
    });

    describe('withGlToast', () => {
      let vueUseSpy;

      beforeEach(() => {
        vueUseSpy = jest.spyOn(Vue, 'use');
      });

      describe('if false (default), GlToast is not registered', () => {
        it('does not call Vue.use with GlToast', () => {
          initMock('<div id="mount-here"></div>');

          expect(vueUseSpy).not.toHaveBeenCalledWith(GlToast);
        });
      });

      describe('if true, registers GlToast', () => {
        it('calls Vue.use with GlToast', () => {
          initMock('<div id="mount-here"></div>', { withGlToast: true });

          expect(vueUseSpy).toHaveBeenCalledWith(GlToast);
        });
      });
    });
  });
});

import { createWrapper } from '@vue/test-utils';
import Vue from 'vue';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initSimpleApp } from '~/helpers/init_simple_app_helper';

const MockComponent = Vue.component('MockComponent', {
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
  render: (createElement) => createElement('span'),
});

let wrapper;

const findMock = () => wrapper.findComponent(MockComponent);

const didCreateApp = () => wrapper !== undefined;

const initMock = (html, props = {}) => {
  setHTMLFixture(html);

  const app = initSimpleApp('#mount-here', MockComponent, { props });

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
});

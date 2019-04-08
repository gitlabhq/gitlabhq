import Vue from 'vue';
import urlComponent from '~/serverless/components/url.vue';
import { shallowMount } from '@vue/test-utils';

const createComponent = uri =>
  shallowMount(Vue.extend(urlComponent), {
    propsData: {
      uri,
    },
    sync: false,
  }).vm;

describe('urlComponent', () => {
  it('should render correctly', () => {
    const uri = 'http://testfunc.apps.example.com';
    const vm = createComponent(uri);

    expect(vm.$el.classList.contains('clipboard-group')).toBe(true);
    expect(vm.$el.querySelector('clipboardbutton-stub').getAttribute('text')).toEqual(uri);

    expect(vm.$el.querySelector('.url-text-field').innerHTML).toEqual(uri);

    vm.$destroy();
  });
});

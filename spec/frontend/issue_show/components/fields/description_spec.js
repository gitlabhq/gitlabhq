import Vue from 'vue';
import eventHub from '~/issue_show/event_hub';
import Store from '~/issue_show/stores';
import descriptionField from '~/issue_show/components/fields/description.vue';
import { keyboardDownEvent } from '../../helpers';

describe('Description field component', () => {
  let vm;
  let store;

  beforeEach(done => {
    const Component = Vue.extend(descriptionField);
    const el = document.createElement('div');
    store = new Store({
      titleHtml: '',
      descriptionHtml: '',
      issuableRef: '',
    });
    store.formState.description = 'test';

    document.body.appendChild(el);

    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

    vm = new Component({
      el,
      propsData: {
        markdownPreviewPath: '/',
        markdownDocsPath: '/',
        formState: store.formState,
      },
    }).$mount();

    Vue.nextTick(done);
  });

  it('renders markdown field with description', () => {
    expect(vm.$el.querySelector('.md-area textarea').value).toBe('test');
  });

  it('renders markdown field with a markdown description', done => {
    store.formState.description = '**test**';

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.md-area textarea').value).toBe('**test**');

      done();
    });
  });

  it('focuses field when mounted', () => {
    expect(document.activeElement).toBe(vm.$refs.textarea);
  });

  it('triggers update with meta+enter', () => {
    vm.$el.querySelector('.md-area textarea').dispatchEvent(keyboardDownEvent(13, true));

    expect(eventHub.$emit).toHaveBeenCalled();
  });

  it('triggers update with ctrl+enter', () => {
    vm.$el.querySelector('.md-area textarea').dispatchEvent(keyboardDownEvent(13, false, true));

    expect(eventHub.$emit).toHaveBeenCalled();
  });

  it('has a ref named `textarea`', () => {
    expect(vm.$refs.textarea).not.toBeNull();
  });
});

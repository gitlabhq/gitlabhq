import Vue from 'vue';
import eventHub from '~/issue_show/event_hub';
import Store from '~/issue_show/stores';
import titleField from '~/issue_show/components/fields/title.vue';
import { keyboardDownEvent } from '../../helpers';

describe('Title field component', () => {
  let vm;
  let store;

  beforeEach(() => {
    const Component = Vue.extend(titleField);
    store = new Store({
      titleHtml: '',
      descriptionHtml: '',
      issuableRef: '',
    });
    store.formState.title = 'test';

    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

    vm = new Component({
      propsData: {
        formState: store.formState,
      },
    }).$mount();
  });

  it('renders form control with formState title', () => {
    expect(vm.$el.querySelector('.form-control').value).toBe('test');
  });

  it('triggers update with meta+enter', () => {
    vm.$el.querySelector('.form-control').dispatchEvent(keyboardDownEvent(13, true));

    expect(eventHub.$emit).toHaveBeenCalled();
  });

  it('triggers update with ctrl+enter', () => {
    vm.$el.querySelector('.form-control').dispatchEvent(keyboardDownEvent(13, false, true));

    expect(eventHub.$emit).toHaveBeenCalled();
  });

  it('has a ref named `input`', () => {
    expect(vm.$refs.input).not.toBeNull();
  });
});

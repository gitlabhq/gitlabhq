import { GlButton, GlFormInput, GlFormTextarea } from '@gitlab/ui';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import TagCreate from '~/releases/components/tag_create.vue';
import RefSelector from '~/ref/components/ref_selector.vue';
import createStore from '~/releases/stores';
import createEditNewModule from '~/releases/stores/modules/edit_new';
import { createRefModule } from '~/ref/stores';

const TEST_PROJECT_ID = '1234';

const VALUE = 'new-tag';

describe('releases/components/tag_create', () => {
  let store;
  let wrapper;
  let mock;

  const createWrapper = () => {
    wrapper = shallowMount(TagCreate, {
      store,
      propsData: { value: VALUE },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    store = createStore({
      modules: {
        editNew: createEditNewModule({
          projectId: TEST_PROJECT_ID,
        }),
        ref: createRefModule(),
      },
    });
    store.state.editNew.release = {
      tagMessage: 'test',
    };
    store.state.editNew.createFrom = 'v1';
    createWrapper();
  });

  afterEach(() => mock.restore());

  const findTagInput = () => wrapper.findComponent(GlFormInput);
  const findTagRef = () => wrapper.findComponent(RefSelector);
  const findTagMessage = () => wrapper.findComponent(GlFormTextarea);
  const findSave = () => {
    const buttons = wrapper.findAllComponents(GlButton);
    return buttons.at(buttons.length - 2);
  };
  const findCancel = () => {
    const buttons = wrapper.findAllComponents(GlButton);
    return buttons.at(buttons.length - 1);
  };

  it('initializes the input with value prop', () => {
    expect(findTagInput().attributes('value')).toBe(VALUE);
  });

  it('emits a change event when the tag name chagnes', () => {
    findTagInput().vm.$emit('input', 'new-value');

    expect(wrapper.emitted('change')).toEqual([['new-value']]);
  });

  it('binds the store value to the ref selector', () => {
    const ref = findTagRef();
    expect(ref.props('value')).toBe('v1');

    ref.vm.$emit('input', 'v2');

    expect(ref.props('value')).toBe('v1');
  });

  it('passes the project id tot he ref selector', () => {
    expect(findTagRef().props('projectId')).toBe(TEST_PROJECT_ID);
  });

  it('binds the store value to the message', async () => {
    const message = findTagMessage();
    expect(message.attributes('value')).toBe('test');

    message.vm.$emit('input', 'hello');

    await nextTick();

    expect(message.attributes('value')).toBe('hello');
  });

  it('emits create event when Save is clicked', () => {
    const button = findSave();

    expect(button.text()).toBe('Save');

    button.vm.$emit('click');

    expect(wrapper.emitted('create')).toEqual([[]]);
  });

  it('emits cancel event when Select another tag is clicked', () => {
    const button = findCancel();

    expect(button.text()).toBe('Select another tag');

    button.vm.$emit('click');

    expect(wrapper.emitted('cancel')).toEqual([[]]);
  });
});

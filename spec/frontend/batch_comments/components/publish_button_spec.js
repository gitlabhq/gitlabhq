import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import PublishButton from '~/batch_comments/components/publish_button.vue';
import { createStore } from '~/batch_comments/stores';

describe('Batch comments publish button component', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    store = createStore();

    wrapper = mount(PublishButton, { store, propsData: { shouldPublish: true } });

    jest.spyOn(store, 'dispatch').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('dispatches publishReview on click', async () => {
    await wrapper.trigger('click');

    expect(store.dispatch).toHaveBeenCalledWith('batchComments/publishReview', undefined);
  });

  it('sets loading when isPublishing is true', async () => {
    store.state.batchComments.isPublishing = true;

    await nextTick();
    expect(wrapper.attributes('disabled')).toBe('disabled');
  });
});

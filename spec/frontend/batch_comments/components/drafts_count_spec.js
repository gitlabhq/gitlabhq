import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import DraftsCount from '~/batch_comments/components/drafts_count.vue';
import { createStore } from '~/batch_comments/stores';

describe('Batch comments drafts count component', () => {
  let store;
  let wrapper;

  beforeEach(() => {
    store = createStore();

    store.state.batchComments.drafts.push('comment');

    wrapper = mount(DraftsCount, { store });
  });

  it('renders count', () => {
    expect(wrapper.text()).toContain('1');
  });

  it('renders screen reader text', async () => {
    const el = wrapper.find('.sr-only');

    expect(el.text()).toContain('draft');

    store.state.batchComments.drafts.push('comment 2');
    await nextTick();

    expect(el.text()).toContain('drafts');
  });
});

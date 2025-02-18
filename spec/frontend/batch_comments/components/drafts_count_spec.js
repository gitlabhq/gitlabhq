import Vue, { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import DraftsCount from '~/batch_comments/components/drafts_count.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { useBatchComments } from '~/batch_comments/store';

Vue.use(PiniaVuePlugin);

describe('Batch comments drafts count component', () => {
  let wrapper;
  let pinia;

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();

    useBatchComments().drafts.push('comment');

    wrapper = mount(DraftsCount, { pinia });
  });

  it('renders count', () => {
    expect(wrapper.text()).toContain('1');
  });

  it('renders screen reader text', async () => {
    const el = wrapper.find('.sr-only');

    expect(el.text()).toContain('draft');

    useBatchComments().drafts.push('comment 2');
    await nextTick();

    expect(el.text()).toContain('drafts');
  });
});

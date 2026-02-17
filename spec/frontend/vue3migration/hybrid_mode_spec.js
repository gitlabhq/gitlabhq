import { mount } from '@vue/test-utils';
import SlotWithFallbackContent from './components/slot_with_fallback_content.vue';

describe('Vue.js 3 + Vue.js 2 compiler edge cases', () => {
  it('correctly renders fallback content', () => {
    const wrapper = mount(SlotWithFallbackContent);
    expect(wrapper.text()).toBe('SlotWithFallbackContent');
  });
});

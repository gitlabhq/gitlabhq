import { mount } from '@vue/test-utils';

import SlotsWithSameName from './components/slots_with_same_name.vue';
import VOnceInsideVIf from './components/v_once_inside_v_if.vue';
import KeyInsideTemplate from './components/key_inside_template.vue';
import CommentsOnRootLevel from './components/comments_on_root_level.vue';
import SlotWithComment from './components/slot_with_comment.vue';
import DefaultSlotWithComment from './components/default_slot_with_comment.vue';

describe('Vue.js 3 compiler edge cases', () => {
  it('workarounds issue #6063 when same slot is used with whitespace preserve', () => {
    expect(() => mount(SlotsWithSameName)).not.toThrow();
  });

  it('workarounds issue #7725 when v-once is used inside v-if', () => {
    expect(() => mount(VOnceInsideVIf)).not.toThrow();
  });

  it('renders vue.js 2 component when key is inside template', () => {
    const wrapper = mount(KeyInsideTemplate);
    expect(wrapper.text()).toBe('12345');
  });

  it('passes attributes to component with trailing comments on root level', () => {
    const wrapper = mount(CommentsOnRootLevel, { propsData: { 'data-testid': 'test' } });
    expect(wrapper.html()).toBe('<div data-testid="test"></div>');
  });

  it('treats empty slots with comments as empty', () => {
    const wrapper = mount(SlotWithComment);
    expect(wrapper.html()).toBe('<div>SimpleComponent</div>');
  });

  it('treats empty default slot with comments as empty', () => {
    const wrapper = mount(DefaultSlotWithComment);
    expect(wrapper.html()).toBe('<div>SimpleComponent</div>');
  });
});

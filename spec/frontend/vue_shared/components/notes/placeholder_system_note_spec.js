import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import placeholderSystemNote from '~/vue_shared/components/notes/placeholder_system_note.vue';

describe('placeholder system note component', () => {
  let PlaceholderSystemNote;
  let vm;

  beforeEach(() => {
    PlaceholderSystemNote = Vue.extend(placeholderSystemNote);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render system note placeholder with plain text', () => {
    vm = mountComponent(PlaceholderSystemNote, {
      note: { body: 'This is a placeholder' },
    });

    expect(vm.$el.tagName).toEqual('LI');
    expect(vm.$el.querySelector('.timeline-content em').textContent.trim()).toEqual(
      'This is a placeholder',
    );
  });
});

import { shallowMount } from '@vue/test-utils';
import SystemNote from '~/rapid_diffs/app/discussions/system_note.vue';
import NoteAuthor from '~/rapid_diffs/app/discussions/note_author.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

describe('SystemNote', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SystemNote, {
      propsData: props,
    });
  };

  it('shows system message', () => {
    const note = { note_html: '<p id="test">test</p>' };
    createComponent({ note });
    expect(wrapper.find('p#test').text()).toBe('test');
  });

  it('shows message author', () => {
    const note = { note_html: 'test', author: { username: 'user' } };
    createComponent({ note });
    const author = wrapper.findComponent(NoteAuthor);
    expect(author.props('author')).toStrictEqual(note.author);
    expect(author.props('showUsername')).toBe(false);
  });

  it('shows deleted author', () => {
    const note = { note_html: 'test' };
    createComponent({ note });
    expect(wrapper.text()).toContain('A deleted user');
  });

  it('shows timestamp', () => {
    const note = { note_html: 'test', created_at: Date.now().toString() };
    createComponent({ note });
    expect(wrapper.findComponent(TimeAgoTooltip).props('time')).toBe(note.created_at);
  });
});

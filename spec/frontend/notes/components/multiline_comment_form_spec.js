import { GlFormSelect } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import MultilineCommentForm from '~/notes/components/multiline_comment_form.vue';
import notesModule from '~/notes/stores/modules';

describe('MultilineCommentForm', () => {
  Vue.use(Vuex);
  const setSelectedCommentPosition = jest.fn();
  const testLine = {
    line_code: 'test',
    type: 'test',
    old_line: 'test',
    new_line: 'test',
  };

  const createWrapper = (props = {}, state) => {
    setSelectedCommentPosition.mockReset();

    const store = new Vuex.Store({
      modules: { notes: notesModule() },
      actions: { setSelectedCommentPosition },
    });
    if (state) store.replaceState({ ...store.state, ...state });

    const propsData = {
      line: { ...testLine },
      commentLineOptions: [{ text: '1' }],
      ...props,
    };
    return mount(MultilineCommentForm, { propsData, store });
  };

  describe('created', () => {
    it('sets commentLineStart to line', () => {
      const line = { ...testLine };
      const wrapper = createWrapper({ line });

      expect(wrapper.vm.commentLineStart).toEqual(line);
      expect(setSelectedCommentPosition).toHaveBeenCalled();
    });

    it('sets commentLineStart to lineRange', () => {
      const lineRange = {
        start: { ...testLine },
      };
      const wrapper = createWrapper({ lineRange });

      expect(wrapper.vm.commentLineStart).toEqual(lineRange.start);
      expect(setSelectedCommentPosition).toHaveBeenCalled();
    });
  });

  describe('destroyed', () => {
    it('calls setSelectedCommentPosition', () => {
      const wrapper = createWrapper();
      wrapper.destroy();

      // Once during created, once during destroyed
      expect(setSelectedCommentPosition).toHaveBeenCalledTimes(2);
    });
  });

  it('handles changing the start line', () => {
    const line = { ...testLine };
    const wrapper = createWrapper({ line });
    const glSelect = wrapper.findComponent(GlFormSelect);

    glSelect.vm.$emit('change', { ...testLine });

    expect(wrapper.vm.commentLineStart).toEqual(line);
    expect(wrapper.emitted('input')).toHaveLength(1);
    // Once during created, once during updateCommentLineStart
    expect(setSelectedCommentPosition).toHaveBeenCalledTimes(2);
  });
});

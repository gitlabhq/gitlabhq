import { GlFormSelect, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import MultilineCommentForm from '~/notes/components/multiline_comment_form.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';

Vue.use(PiniaVuePlugin);

describe('MultilineCommentForm', () => {
  let wrapper;
  let pinia;

  const testLine = {
    line_code: 'test',
    type: 'test',
    old_line: 'test',
    new_line: 'test',
  };

  const createWrapper = (props = {}) => {
    const propsData = {
      line: { ...testLine },
      commentLineOptions: [{ text: '1' }],
      ...props,
    };
    wrapper = shallowMount(MultilineCommentForm, { propsData, pinia, stubs: { GlSprintf } });
  };

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
  });

  describe('created', () => {
    it('sets commentLineStart to line', () => {
      const line = { ...testLine };
      createWrapper({ line });

      // we can't check for .attributes() because of GlFormSelect design
      // all the attributes get converted to a string, so the line object becomes [object Object]
      // we can test for the component internals instead which is as reliable as VTUs checks
      expect(wrapper.findComponent(GlFormSelect).vm.$attrs.value).toEqual(line);
      expect(useNotes().setSelectedCommentPosition).toHaveBeenCalled();
    });

    it('sets commentLineStart to lineRange', () => {
      const lineRange = {
        start: { ...testLine },
      };
      createWrapper({ lineRange });

      expect(wrapper.findComponent(GlFormSelect).vm.$attrs.value).toEqual(lineRange.start);
      expect(useNotes().setSelectedCommentPosition).toHaveBeenCalled();
    });
  });

  describe('destroyed', () => {
    it('calls setSelectedCommentPosition', () => {
      createWrapper();
      wrapper.destroy();

      // Once during created, once during destroyed
      expect(useNotes().setSelectedCommentPosition).toHaveBeenCalledTimes(2);
    });
  });

  it('handles changing the start line', () => {
    const line = { ...testLine };
    createWrapper({ line });
    const glSelect = wrapper.findComponent(GlFormSelect);

    glSelect.vm.$emit('change', { ...testLine });

    expect(wrapper.findComponent(GlFormSelect).vm.$attrs.value).toEqual(line);
    expect(wrapper.emitted('input')).toHaveLength(1);
    // Once during created, once during updateCommentLineStart
    expect(useNotes().setSelectedCommentPosition).toHaveBeenCalledTimes(2);
  });
});

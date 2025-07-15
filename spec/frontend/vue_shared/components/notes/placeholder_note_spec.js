import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import IssuePlaceholderNote from '~/vue_shared/components/notes/placeholder_note.vue';
import { userDataMock } from 'jest/notes/mock_data';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';

Vue.use(PiniaVuePlugin);

describe('Issue placeholder note component', () => {
  let pinia;
  let wrapper;

  const findNote = () => wrapper.findComponent({ ref: 'note' });

  const createComponent = (isIndividual = false, propsData = {}) => {
    wrapper = shallowMount(IssuePlaceholderNote, {
      pinia,
      propsData: {
        note: {
          body: 'Foo',
          individual_note: isIndividual,
        },
        ...propsData,
      },
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes().userData = userDataMock;
  });

  it('matches snapshot', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('does not add "discussion" class to individual notes', () => {
    createComponent(true);

    expect(findNote().classes()).not.toContain('discussion');
  });

  it('adds "discussion" class to non-individual notes', () => {
    createComponent();

    expect(findNote().classes()).toContain('discussion');
  });
});

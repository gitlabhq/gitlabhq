import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import IssuePlaceholderNote from '~/vue_shared/components/notes/placeholder_note.vue';
import { userDataMock } from 'jest/notes/mock_data';

Vue.use(Vuex);

const getters = {
  getUserData: () => userDataMock,
};

describe('Issue placeholder note component', () => {
  let wrapper;

  const findNote = () => wrapper.findComponent({ ref: 'note' });

  const createComponent = (isIndividual = false, propsData = {}) => {
    wrapper = shallowMount(IssuePlaceholderNote, {
      store: new Vuex.Store({
        getters,
      }),
      propsData: {
        note: {
          body: 'Foo',
          individual_note: isIndividual,
        },
        ...propsData,
      },
    });
  };

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

import { shallowMount } from '@vue/test-utils';
import SnippetDescription from '~/snippets/components/snippet_description_view.vue';

describe('Snippet Description component', () => {
  let wrapper;
  const description = '<h2>The property of Thor</h2>';

  function createComponent() {
    wrapper = shallowMount(SnippetDescription, {
      propsData: {
        description,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  it('matches the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});

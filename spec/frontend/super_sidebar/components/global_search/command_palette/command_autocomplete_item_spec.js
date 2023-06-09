import { shallowMount } from '@vue/test-utils';
import CommandAutocompleteItem from '~/super_sidebar/components/global_search/command_palette/command_autocomplete_item.vue';
import { linksReducer } from '~/super_sidebar/components/global_search/command_palette/utils';
import { LINKS } from './mock_data';

describe('CommandAutocompleteItem', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(CommandAutocompleteItem, {
      propsData: {
        command: LINKS.reduce(linksReducer, [])[1],
        searchQuery: 'root',
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('should render user item', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});

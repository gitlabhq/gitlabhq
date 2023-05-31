import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FakeSearchInput from '~/super_sidebar/components/global_search/command_palette/fake_search_input.vue';
import {
  COMMAND_HANDLE,
  SEARCH_SCOPE,
} from '~/super_sidebar/components/global_search/command_palette/constants';

describe('FakeSearchInput', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMountExtended(FakeSearchInput, {
      propsData: {
        scope: COMMAND_HANDLE,
        userInput: '',
        ...props,
      },
    });
  };

  const findSearchScope = () => wrapper.findByTestId('search-scope');
  const findSearchScopePlaceholder = () => wrapper.findByTestId('search-scope-placeholder');

  it('should render the search scope', () => {
    createComponent();
    expect(findSearchScope().text()).toBe(COMMAND_HANDLE);
  });

  describe('placeholder', () => {
    it('should render the placeholder for its search scope when there is no user input', () => {
      createComponent();
      expect(findSearchScopePlaceholder().text()).toBe(SEARCH_SCOPE[COMMAND_HANDLE]);
    });

    it('should NOT render the placeholder when there is user input', () => {
      createComponent({ userInput: 'todo' });
      expect(findSearchScopePlaceholder().exists()).toBe(false);
    });
  });
});

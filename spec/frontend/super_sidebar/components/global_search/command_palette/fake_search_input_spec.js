import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FakeSearchInput from '~/super_sidebar/components/global_search/command_palette/fake_search_input.vue';
import {
  SEARCH_SCOPE_PLACEHOLDER,
  COMMON_HANDLES,
  COMMAND_HANDLE,
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
    it.each(COMMON_HANDLES)(
      'should render the placeholder for the %s scope when there is no user input',
      (scope) => {
        createComponent({ scope });
        expect(findSearchScopePlaceholder().text()).toBe(SEARCH_SCOPE_PLACEHOLDER[scope]);
      },
    );

    it('should NOT render the placeholder when there is user input', () => {
      createComponent({ userInput: 'todo' });
      expect(findSearchScopePlaceholder().exists()).toBe(false);
    });
  });
});

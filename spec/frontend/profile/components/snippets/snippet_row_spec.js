import SnippetRow from '~/profile/components/snippets/snippet_row.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { MOCK_USER, MOCK_SNIPPET } from 'jest/profile/mock_data';

describe('UserProfileSnippetRow', () => {
  let wrapper;

  const defaultProps = {
    userInfo: MOCK_USER,
    snippet: MOCK_SNIPPET,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(SnippetRow, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders snippet title', () => {
      expect(wrapper.text()).toBe(MOCK_SNIPPET.title);
    });
  });
});

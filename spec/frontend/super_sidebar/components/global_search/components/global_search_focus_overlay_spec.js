import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SearchResultFocusLayover from '~/super_sidebar/components/global_search/components/global_search_focus_overlay.vue';

describe('SearchResultFocusLayover', () => {
  let wrapper;

  const createComponent = (textMessage = 'test') => {
    wrapper = shallowMountExtended(SearchResultFocusLayover, {
      propsData: {
        textMessage,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findOverlayMessage = () => wrapper.findByTestId('overlay-message');

  describe('Render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders correctly', () => {
      expect(findOverlayMessage().exists()).toBe(true);
    });

    describe.each`
      text                                 | result
      ${'Go to %{kbdStart}↵%{kbdEnd}'}     | ${'Go to %{kbdStart}↵%{kbdEnd}'}
      ${'Go to %{kbdStart}ABC%{kbdEnd}'}   | ${'Go to %{kbdStart}ABC%{kbdEnd}'}
      ${'Go to'}                           | ${'Go to'}
      ${'Go to %{linkStart}ABC%{linkEnd}'} | ${'Go to %{linkStart}ABC%{linkEnd}'}
    `('renders the layover text correctly', ({ text, result }) => {
      beforeEach(() => {
        createComponent(text);
      });

      it('renders the layover component', () => {
        expect(wrapper.props('textMessage')).toBe(result);
      });
    });
  });
});

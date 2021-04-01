import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CommitCommentsButton from '~/projects/commit/components/commit_comments_button.vue';

describe('CommitCommentsButton', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(CommitCommentsButton, {
        propsData: {
          commentsCount: 1,
          ...props,
        },
      }),
    );
  };

  const tooltip = () => wrapper.findByTestId('comment-button-wrapper');

  describe('Comment Button', () => {
    it('has proper tooltip and button attributes for 1 comment', () => {
      createComponent();

      expect(tooltip().attributes('title')).toBe('1 comment on this commit');
      expect(tooltip().text()).toBe('1');
    });

    it('has proper tooltip and button attributes for multiple comments', () => {
      createComponent({ commentsCount: 2 });

      expect(tooltip().attributes('title')).toBe('2 comments on this commit');
      expect(tooltip().text()).toBe('2');
    });

    it('does not show when there are no comments', () => {
      createComponent({ commentsCount: 0 });

      expect(tooltip().exists()).toBe(false);
    });
  });
});

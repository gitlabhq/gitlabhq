/* global Mousetrap */
import 'mousetrap';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import DiscussionKeyboardNavigator from '~/notes/components/discussion_keyboard_navigator.vue';

describe('notes/components/discussion_keyboard_navigator', () => {
  const localVue = createLocalVue();

  let wrapper;
  let jumpToNextDiscussion;
  let jumpToPreviousDiscussion;

  const createComponent = () => {
    wrapper = shallowMount(DiscussionKeyboardNavigator, {
      mixins: [
        localVue.extend({
          methods: {
            jumpToNextDiscussion,
            jumpToPreviousDiscussion,
          },
        }),
      ],
    });
  };

  beforeEach(() => {
    jumpToNextDiscussion = jest.fn();
    jumpToPreviousDiscussion = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('on mount', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls jumpToNextDiscussion when pressing `n`', () => {
      Mousetrap.trigger('n');

      expect(jumpToNextDiscussion).toHaveBeenCalled();
    });

    it('calls jumpToPreviousDiscussion when pressing `p`', () => {
      Mousetrap.trigger('p');

      expect(jumpToPreviousDiscussion).toHaveBeenCalled();
    });
  });

  describe('on destroy', () => {
    beforeEach(() => {
      jest.spyOn(Mousetrap, 'unbind');

      createComponent();

      wrapper.destroy();
    });

    it('unbinds keys', () => {
      expect(Mousetrap.unbind).toHaveBeenCalledWith('n');
      expect(Mousetrap.unbind).toHaveBeenCalledWith('p');
    });

    it('does not call jumpToNextDiscussion when pressing `n`', () => {
      Mousetrap.trigger('n');

      expect(jumpToNextDiscussion).not.toHaveBeenCalled();
    });

    it('does not call jumpToNextDiscussion when pressing `p`', () => {
      Mousetrap.trigger('p');

      expect(jumpToPreviousDiscussion).not.toHaveBeenCalled();
    });
  });
});

import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import {
  keysFor,
  MR_NEXT_UNRESOLVED_DISCUSSION,
  MR_PREVIOUS_UNRESOLVED_DISCUSSION,
} from '~/behaviors/shortcuts/keybindings';
import { Mousetrap } from '~/lib/mousetrap';
import DiscussionNavigator from '~/notes/components/discussion_navigator.vue';
import eventHub from '~/notes/event_hub';

describe('notes/components/discussion_navigator', () => {
  let wrapper;
  let jumpToNextDiscussion;
  let jumpToPreviousDiscussion;

  const createComponent = () => {
    wrapper = shallowMount(DiscussionNavigator, {
      mixins: [
        {
          methods: {
            jumpToNextDiscussion,
            jumpToPreviousDiscussion,
          },
        },
      ],
    });
  };

  beforeEach(() => {
    jumpToNextDiscussion = jest.fn();
    jumpToPreviousDiscussion = jest.fn();
  });

  describe('on create', () => {
    let onSpy;
    let vm;

    beforeEach(() => {
      onSpy = jest.spyOn(eventHub, '$on');
      vm = new Vue(DiscussionNavigator);
    });

    it('listens for jumpToFirstUnresolvedDiscussion events', () => {
      expect(onSpy).toHaveBeenCalledWith(
        'jumpToFirstUnresolvedDiscussion',
        vm.jumpToFirstUnresolvedDiscussion,
      );
    });
  });

  describe('on mount', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls jumpToNextDiscussion when pressing `n`', () => {
      Mousetrap.trigger(keysFor(MR_NEXT_UNRESOLVED_DISCUSSION));

      expect(jumpToNextDiscussion).toHaveBeenCalled();
    });

    it('calls jumpToPreviousDiscussion when pressing `p`', () => {
      Mousetrap.trigger(keysFor(MR_PREVIOUS_UNRESOLVED_DISCUSSION));

      expect(jumpToPreviousDiscussion).toHaveBeenCalled();
    });
  });

  describe('on destroy', () => {
    let jumpFn;

    beforeEach(() => {
      jest.spyOn(Mousetrap, 'unbind');
      jest.spyOn(eventHub, '$off');

      createComponent();

      jumpFn = wrapper.vm.jumpToFirstUnresolvedDiscussion;

      wrapper.destroy();
    });

    it('unbinds keys', () => {
      expect(Mousetrap.unbind).toHaveBeenCalledWith(keysFor(MR_NEXT_UNRESOLVED_DISCUSSION));
      expect(Mousetrap.unbind).toHaveBeenCalledWith(keysFor(MR_PREVIOUS_UNRESOLVED_DISCUSSION));
    });

    it('unbinds event hub listeners', () => {
      expect(eventHub.$off).toHaveBeenCalledWith('jumpToFirstUnresolvedDiscussion', jumpFn);
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

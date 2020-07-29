/* global Mousetrap */
import 'mousetrap';
import Vue from 'vue';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import DiscussionNavigator from '~/notes/components/discussion_navigator.vue';
import eventHub from '~/notes/event_hub';

describe('notes/components/discussion_navigator', () => {
  const localVue = createLocalVue();

  let wrapper;
  let jumpToNextDiscussion;
  let jumpToPreviousDiscussion;

  const createComponent = () => {
    wrapper = shallowMount(DiscussionNavigator, {
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
    if (wrapper) {
      wrapper.destroy();
    }
    wrapper = null;
  });

  describe('on create', () => {
    let onSpy;
    let vm;

    beforeEach(() => {
      onSpy = jest.spyOn(eventHub, '$on');
      vm = new (Vue.extend(DiscussionNavigator))();
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
      Mousetrap.trigger('n');

      expect(jumpToNextDiscussion).toHaveBeenCalled();
    });

    it('calls jumpToPreviousDiscussion when pressing `p`', () => {
      Mousetrap.trigger('p');

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
      expect(Mousetrap.unbind).toHaveBeenCalledWith('n');
      expect(Mousetrap.unbind).toHaveBeenCalledWith('p');
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

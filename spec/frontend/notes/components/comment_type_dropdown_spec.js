import { GlButton, GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CommentTypeDropdown from '~/notes/components/comment_type_dropdown.vue';
import * as constants from '~/notes/constants';
import { COMMENT_FORM } from '~/notes/i18n';

describe('CommentTypeDropdown component', () => {
  let wrapper;

  const findCommentButton = () => wrapper.findComponent(GlButton);
  const findCommentListboxOption = () => wrapper.findAllComponents(GlListboxItem).at(0);
  const findDiscussionListboxOption = () => wrapper.findAllComponents(GlListboxItem).at(1);

  const mountComponent = ({ props = {} } = {}) => {
    wrapper = extendedWrapper(
      mount(CommentTypeDropdown, {
        propsData: {
          noteableDisplayName: 'issue',
          noteType: constants.COMMENT,
          ...props,
        },
        stubs: {
          GlCollapsibleListbox,
          GlListboxItem,
        },
      }),
    );
  };

  it.each`
    isInternalNote | buttonText
    ${false}       | ${COMMENT_FORM.comment}
    ${true}        | ${COMMENT_FORM.internalComment}
  `(
    'Should label action button as "$buttonText" for comment when `isInternalNote` is $isInternalNote',
    ({ isInternalNote, buttonText }) => {
      mountComponent({ props: { noteType: constants.COMMENT, isInternalNote } });

      expect(findCommentButton().text()).toBe(buttonText);
    },
  );

  it('Should set correct dropdown item checked when comment is selected', () => {
    mountComponent({ props: { noteType: constants.COMMENT } });

    expect(findCommentListboxOption().props('isSelected')).toBe(true);
    expect(findDiscussionListboxOption().props('isSelected')).toBe(false);
  });

  it.each`
    isInternalNote | buttonText
    ${false}       | ${COMMENT_FORM.startThread}
    ${true}        | ${COMMENT_FORM.startInternalThread}
  `(
    'Should label action button as "$buttonText" for discussion when `isInternalNote` is $isInternalNote',
    ({ isInternalNote, buttonText }) => {
      mountComponent({ props: { noteType: constants.DISCUSSION, isInternalNote } });

      expect(findCommentButton().text()).toBe(buttonText);
    },
  );

  it('Should set correct dropdown item option checked when discussion is selected', () => {
    mountComponent({ props: { noteType: constants.DISCUSSION } });

    expect(findCommentListboxOption().props('isSelected')).toBe(false);
    expect(findDiscussionListboxOption().props('isSelected')).toBe(true);
  });

  it('Should emit `change` event when clicking on an alternate dropdown option', () => {
    mountComponent({ props: { noteType: constants.DISCUSSION } });

    findCommentListboxOption().trigger('click');
    findDiscussionListboxOption().trigger('click');

    expect(wrapper.emitted('change')[0]).toEqual([constants.COMMENT]);
    expect(wrapper.emitted('change').length).toEqual(1);
  });

  it('Should emit `click` event when clicking on the action button', () => {
    mountComponent({ props: { noteType: constants.DISCUSSION } });

    findCommentButton().vm.$emit('click');

    expect(wrapper.emitted('click').length > 0).toBe(true);
  });
});

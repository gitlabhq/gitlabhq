import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CommentTypeDropdown from '~/notes/components/comment_type_dropdown.vue';
import * as constants from '~/notes/constants';
import { COMMENT_FORM } from '~/notes/i18n';

describe('CommentTypeDropdown component', () => {
  let wrapper;

  const findCommentGlDropdown = () => wrapper.findComponent(GlDropdown);
  const findCommentDropdownOption = () => wrapper.findAllComponents(GlDropdownItem).at(0);
  const findDiscussionDropdownOption = () => wrapper.findAllComponents(GlDropdownItem).at(1);

  const mountComponent = ({ props = {} } = {}) => {
    wrapper = extendedWrapper(
      mount(CommentTypeDropdown, {
        propsData: {
          noteableDisplayName: 'issue',
          noteType: constants.COMMENT,
          ...props,
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

      expect(findCommentGlDropdown().props()).toMatchObject({ text: buttonText });
    },
  );

  it('Should set correct dropdown item checked when comment is selected', () => {
    mountComponent({ props: { noteType: constants.COMMENT } });

    expect(findCommentDropdownOption().props()).toMatchObject({ isChecked: true });
    expect(findDiscussionDropdownOption().props()).toMatchObject({ isChecked: false });
  });

  it.each`
    isInternalNote | buttonText
    ${false}       | ${COMMENT_FORM.startThread}
    ${true}        | ${COMMENT_FORM.startInternalThread}
  `(
    'Should label action button as "$buttonText" for discussion when `isInternalNote` is $isInternalNote',
    ({ isInternalNote, buttonText }) => {
      mountComponent({ props: { noteType: constants.DISCUSSION, isInternalNote } });

      expect(findCommentGlDropdown().props()).toMatchObject({ text: buttonText });
    },
  );

  it('Should set correct dropdown item option checked when discussion is selected', () => {
    mountComponent({ props: { noteType: constants.DISCUSSION } });

    expect(findCommentDropdownOption().props()).toMatchObject({ isChecked: false });
    expect(findDiscussionDropdownOption().props()).toMatchObject({ isChecked: true });
  });

  it('Should emit `change` event when clicking on an alternate dropdown option', () => {
    mountComponent({ props: { noteType: constants.DISCUSSION } });

    const event = {
      type: 'click',
      stopPropagation: jest.fn(),
      preventDefault: jest.fn(),
    };

    findCommentDropdownOption().vm.$emit('click', event);
    findDiscussionDropdownOption().vm.$emit('click', event);

    // ensure the native events don't trigger anything
    expect(event.stopPropagation).toHaveBeenCalledTimes(2);
    expect(event.preventDefault).toHaveBeenCalledTimes(2);

    expect(wrapper.emitted('change')[0]).toEqual([constants.COMMENT]);
    expect(wrapper.emitted('change').length).toEqual(1);
  });

  it('Should emit `click` event when clicking on the action button', () => {
    mountComponent({ props: { noteType: constants.DISCUSSION } });

    findCommentGlDropdown().vm.$emit('click');

    expect(wrapper.emitted('click').length > 0).toBe(true);
  });
});

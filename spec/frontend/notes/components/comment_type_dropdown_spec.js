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

  afterEach(() => {
    wrapper.destroy();
  });

  it('Should label action button "Comment" and correct dropdown item checked when selected', () => {
    mountComponent({ props: { noteType: constants.COMMENT } });

    expect(findCommentGlDropdown().props()).toMatchObject({ text: COMMENT_FORM.comment });
    expect(findCommentDropdownOption().props()).toMatchObject({ isChecked: true });
    expect(findDiscussionDropdownOption().props()).toMatchObject({ isChecked: false });
  });

  it('Should label action button "Start Thread" and correct dropdown item option checked when selected', () => {
    mountComponent({ props: { noteType: constants.DISCUSSION } });

    expect(findCommentGlDropdown().props()).toMatchObject({ text: COMMENT_FORM.startThread });
    expect(findCommentDropdownOption().props()).toMatchObject({ isChecked: false });
    expect(findDiscussionDropdownOption().props()).toMatchObject({ isChecked: true });
  });

  it('Should emit `change` event when clicking on an alternate dropdown option', () => {
    mountComponent({ props: { noteType: constants.DISCUSSION } });

    findCommentDropdownOption().vm.$emit('click');
    findDiscussionDropdownOption().vm.$emit('click');

    expect(wrapper.emitted('change')[0]).toEqual([constants.COMMENT]);
    expect(wrapper.emitted('change').length).toEqual(1);
  });

  it('Should emit `click` event when clicking on the action button', () => {
    mountComponent({ props: { noteType: constants.DISCUSSION } });

    findCommentGlDropdown().vm.$emit('click');

    expect(wrapper.emitted('click').length > 0).toBe(true);
  });
});

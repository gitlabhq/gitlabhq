import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import { mockTracking, triggerEvent } from 'helpers/tracking_helper';
import Component from '~/sidebar/components/reviewers/reviewer_title.vue';

describe('ReviewerTitle component', () => {
  let wrapper;

  const createComponent = props => {
    return shallowMount(Component, {
      propsData: {
        numberOfReviewers: 0,
        editable: false,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('reviewer title', () => {
    it('renders reviewer', () => {
      wrapper = createComponent({
        numberOfReviewers: 1,
        editable: false,
      });

      expect(wrapper.vm.$el.innerText.trim()).toEqual('Reviewer');
    });

    it('renders 2 reviewers', () => {
      wrapper = createComponent({
        numberOfReviewers: 2,
        editable: false,
      });

      expect(wrapper.vm.$el.innerText.trim()).toEqual('2 Reviewers');
    });
  });

  describe('gutter toggle', () => {
    it('does not show toggle by default', () => {
      wrapper = createComponent({
        numberOfReviewers: 2,
        editable: false,
      });

      expect(wrapper.vm.$el.querySelector('.gutter-toggle')).toBeNull();
    });

    it('shows toggle when showToggle is true', () => {
      wrapper = createComponent({
        numberOfReviewers: 2,
        editable: false,
        showToggle: true,
      });

      expect(wrapper.vm.$el.querySelector('.gutter-toggle')).toEqual(expect.any(Object));
    });
  });

  it('does not render spinner by default', () => {
    wrapper = createComponent({
      numberOfReviewers: 0,
      editable: false,
    });

    expect(wrapper.find(GlLoadingIcon).exists()).toBeFalsy();
  });

  it('renders spinner when loading', () => {
    wrapper = createComponent({
      loading: true,
      numberOfReviewers: 0,
      editable: false,
    });

    expect(wrapper.find(GlLoadingIcon).exists()).toBeTruthy();
  });

  it('does not render edit link when not editable', () => {
    wrapper = createComponent({
      numberOfReviewers: 0,
      editable: false,
    });

    expect(wrapper.vm.$el.querySelector('.edit-link')).toBeNull();
  });

  it('renders edit link when editable', () => {
    wrapper = createComponent({
      numberOfReviewers: 0,
      editable: true,
    });

    expect(wrapper.vm.$el.querySelector('.edit-link')).not.toBeNull();
  });

  it('tracks the event when edit is clicked', () => {
    wrapper = createComponent({
      numberOfReviewers: 0,
      editable: true,
    });

    const spy = mockTracking('_category_', wrapper.element, jest.spyOn);
    triggerEvent('.js-sidebar-dropdown-toggle');

    expect(spy).toHaveBeenCalledWith('_category_', 'click_edit_button', {
      label: 'right_sidebar',
      property: 'reviewer',
    });
  });
});

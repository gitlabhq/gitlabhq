import { GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { mockTracking, triggerEvent } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Component from '~/sidebar/components/reviewers/reviewer_title.vue';

describe('ReviewerTitle component', () => {
  let wrapper;

  const createComponent = (props, { reviewerAssignDrawer = false } = {}) => {
    return mount(Component, {
      propsData: {
        numberOfReviewers: 0,
        editable: false,
        ...props,
      },
      provide: {
        projectPath: 'gitlab-org/gitlab',
        issuableId: '1',
        issuableIid: '1',
        multipleApprovalRulesAvailable: false,
        glFeatures: {
          reviewerAssignDrawer,
        },
      },
    });
  };

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

  it('does not render spinner by default', () => {
    wrapper = createComponent({
      numberOfReviewers: 0,
      editable: false,
    });

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
  });

  it('renders spinner when loading', () => {
    wrapper = createComponent({
      loading: true,
      numberOfReviewers: 0,
      editable: false,
    });

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
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

  describe('when reviewerAssignDrawer is enabled', () => {
    beforeEach(() => {
      setHTMLFixture('<div id="js-reviewer-drawer-portal"></div>');
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('clicking toggle opens reviewer drawer', async () => {
      wrapper = createComponent(
        {
          editable: true,
        },
        { reviewerAssignDrawer: true },
      );

      expect(document.querySelector('.gl-drawer')).toBe(null);

      wrapper.find('[data-testid="drawer-toggle"]').vm.$emit('click');

      await waitForPromises();

      expect(document.querySelector('.gl-drawer')).not.toBe(null);
    });
  });
});

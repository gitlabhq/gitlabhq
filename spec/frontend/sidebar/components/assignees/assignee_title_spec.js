import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { mockTracking, triggerEvent } from 'helpers/tracking_helper';
import Component from '~/sidebar/components/assignees/assignee_title.vue';

describe('AssigneeTitle component', () => {
  let wrapper;

  const createComponent = (props) => {
    return shallowMount(Component, {
      propsData: {
        numberOfAssignees: 0,
        editable: false,
        changing: false,
        ...props,
      },
    });
  };

  describe('assignee title', () => {
    it('renders assignee', () => {
      wrapper = createComponent({
        numberOfAssignees: 1,
        editable: false,
      });

      expect(wrapper.vm.$el.innerText.trim()).toEqual('Assignee');
    });

    it('renders 2 assignees', () => {
      wrapper = createComponent({
        numberOfAssignees: 2,
        editable: false,
      });

      expect(wrapper.vm.$el.innerText.trim()).toEqual('2 Assignees');
    });
  });

  describe('when changing is false', () => {
    it('renders "Edit"', () => {
      wrapper = createComponent({ editable: true });

      expect(wrapper.find('[data-test-id="edit-link"]').text()).toEqual('Edit');
    });
  });

  describe('when changing is true', () => {
    it('renders "Edit"', () => {
      wrapper = createComponent({ editable: true, changing: true });

      expect(wrapper.find('[data-test-id="edit-link"]').text()).toEqual('Apply');
    });
  });

  it('does not render spinner by default', () => {
    wrapper = createComponent({
      numberOfAssignees: 0,
      editable: false,
    });

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
  });

  it('renders spinner when loading', () => {
    wrapper = createComponent({
      loading: true,
      numberOfAssignees: 0,
      editable: false,
    });

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('does not render edit link when not editable', () => {
    wrapper = createComponent({
      numberOfAssignees: 0,
      editable: false,
    });

    expect(wrapper.vm.$el.querySelector('.edit-link')).toBeNull();
  });

  it('renders edit link when editable', () => {
    wrapper = createComponent({
      numberOfAssignees: 0,
      editable: true,
    });

    expect(wrapper.vm.$el.querySelector('.edit-link')).not.toBeNull();
  });

  it('tracks the event when edit is clicked', () => {
    wrapper = createComponent({
      numberOfAssignees: 0,
      editable: true,
    });

    const spy = mockTracking('_category_', wrapper.element, jest.spyOn);
    triggerEvent('.js-sidebar-dropdown-toggle');

    expect(spy).toHaveBeenCalledWith('_category_', 'click_edit_button', {
      label: 'right_sidebar',
      property: 'assignee',
    });
  });
});

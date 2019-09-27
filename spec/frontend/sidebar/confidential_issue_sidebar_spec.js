import { shallowMount } from '@vue/test-utils';
import ConfidentialIssueSidebar from '~/sidebar/components/confidential/confidential_issue_sidebar.vue';
import { mockTracking, triggerEvent } from 'helpers/tracking_helper';
import EditForm from '~/sidebar/components/confidential/edit_form.vue';

describe('Confidential Issue Sidebar Block', () => {
  let wrapper;

  const createComponent = propsData => {
    const service = {
      update: () => Promise.resolve(true),
    };

    wrapper = shallowMount(ConfidentialIssueSidebar, {
      propsData: {
        service,
        ...propsData,
      },
      sync: false,
    });
  };

  it.each`
    isConfidential | isEditable
    ${false}       | ${false}
    ${false}       | ${true}
    ${true}        | ${false}
    ${true}        | ${true}
  `(
    'renders for isConfidential = $isConfidential and isEditable = $isEditable',
    ({ isConfidential, isEditable }) => {
      createComponent({
        isConfidential,
        isEditable,
      });

      expect(wrapper.element).toMatchSnapshot();
    },
  );

  afterEach(() => {
    wrapper.destroy();
  });

  describe('if editable', () => {
    beforeEach(() => {
      createComponent({
        isConfidential: true,
        isEditable: true,
      });
    });

    it('displays the edit form when editable', () => {
      wrapper.setData({ edit: false });

      wrapper.find({ ref: 'editLink' }).trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(EditForm).exists()).toBe(true);
      });
    });

    it('displays the edit form when opened from collapsed state', () => {
      wrapper.setData({ edit: false });

      wrapper.find({ ref: 'collapseIcon' }).trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(EditForm).exists()).toBe(true);
      });
    });

    it('tracks the event when "Edit" is clicked', () => {
      const spy = mockTracking('_category_', wrapper.element, jest.spyOn);

      const editLink = wrapper.find({ ref: 'editLink' });
      triggerEvent(editLink.element);

      expect(spy).toHaveBeenCalledWith('_category_', 'click_edit_button', {
        label: 'right_sidebar',
        property: 'confidentiality',
      });
    });
  });
});

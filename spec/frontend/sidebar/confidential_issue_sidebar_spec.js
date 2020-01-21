import { shallowMount } from '@vue/test-utils';
import { mockTracking, triggerEvent } from 'helpers/tracking_helper';
import ConfidentialIssueSidebar from '~/sidebar/components/confidential/confidential_issue_sidebar.vue';
import EditForm from '~/sidebar/components/confidential/edit_form.vue';
import SidebarService from '~/sidebar/services/sidebar_service';
import createFlash from '~/flash';
import RecaptchaModal from '~/vue_shared/components/recaptcha_modal';

jest.mock('~/flash');
jest.mock('~/sidebar/services/sidebar_service');

describe('Confidential Issue Sidebar Block', () => {
  let wrapper;

  const findRecaptchaModal = () => wrapper.find(RecaptchaModal);

  const triggerUpdateConfidentialAttribute = () => {
    wrapper.setData({ edit: true });
    return (
      // wait for edit form to become visible
      wrapper.vm
        .$nextTick()
        .then(() => {
          const editForm = wrapper.find(EditForm);
          const { updateConfidentialAttribute } = editForm.props();
          updateConfidentialAttribute();
        })
        // wait for reCAPTCHA modal to render
        .then(() => wrapper.vm.$nextTick())
    );
  };

  const createComponent = propsData => {
    const service = new SidebarService();
    wrapper = shallowMount(ConfidentialIssueSidebar, {
      propsData: {
        service,
        ...propsData,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(window.location, 'reload').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
  });

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

  describe('if editable', () => {
    beforeEach(() => {
      createComponent({
        isConfidential: true,
        isEditable: true,
      });
    });

    it('displays the edit form when editable', () => {
      wrapper.setData({ edit: false });

      return wrapper.vm
        .$nextTick()
        .then(() => {
          wrapper.find({ ref: 'editLink' }).trigger('click');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(wrapper.find(EditForm).exists()).toBe(true);
        });
    });

    it('displays the edit form when opened from collapsed state', () => {
      wrapper.setData({ edit: false });

      return wrapper.vm
        .$nextTick()
        .then(() => {
          wrapper.find({ ref: 'collapseIcon' }).trigger('click');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
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

    describe('for successful update', () => {
      beforeEach(() => {
        SidebarService.prototype.update.mockResolvedValue({ data: 'irrelevant' });
      });

      it('reloads the page', () =>
        triggerUpdateConfidentialAttribute().then(() => {
          expect(window.location.reload).toHaveBeenCalled();
        }));

      it('does not show an error message', () =>
        triggerUpdateConfidentialAttribute().then(() => {
          expect(createFlash).not.toHaveBeenCalled();
        }));
    });

    describe('for update error', () => {
      beforeEach(() => {
        SidebarService.prototype.update.mockRejectedValue(new Error('updating failed!'));
      });

      it('does not reload the page', () =>
        triggerUpdateConfidentialAttribute().then(() => {
          expect(window.location.reload).not.toHaveBeenCalled();
        }));

      it('shows an error message', () =>
        triggerUpdateConfidentialAttribute().then(() => {
          expect(createFlash).toHaveBeenCalled();
        }));
    });

    describe('for spam error', () => {
      beforeEach(() => {
        SidebarService.prototype.update.mockRejectedValue({ name: 'SpamError' });
      });

      it('does not reload the page', () =>
        triggerUpdateConfidentialAttribute().then(() => {
          expect(window.location.reload).not.toHaveBeenCalled();
        }));

      it('does not show an error message', () =>
        triggerUpdateConfidentialAttribute().then(() => {
          expect(createFlash).not.toHaveBeenCalled();
        }));

      it('shows a reCAPTCHA modal', () => {
        expect(findRecaptchaModal().exists()).toBe(false);

        return triggerUpdateConfidentialAttribute().then(() => {
          expect(findRecaptchaModal().exists()).toBe(true);
        });
      });
    });
  });
});

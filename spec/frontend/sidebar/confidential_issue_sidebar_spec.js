import Vue from 'vue';
import confidentialIssueSidebar from '~/sidebar/components/confidential/confidential_issue_sidebar.vue';
import { mockTracking, triggerEvent } from 'helpers/tracking_helper';

describe('Confidential Issue Sidebar Block', () => {
  let vm1;
  let vm2;

  beforeEach(() => {
    const Component = Vue.extend(confidentialIssueSidebar);
    const service = {
      update: () => Promise.resolve(true),
    };

    vm1 = new Component({
      propsData: {
        isConfidential: true,
        isEditable: true,
        service,
      },
    }).$mount();

    vm2 = new Component({
      propsData: {
        isConfidential: false,
        isEditable: false,
        service,
      },
    }).$mount();
  });

  it('shows if confidential and/or editable', () => {
    expect(vm1.$el.innerHTML.includes('Edit')).toBe(true);

    expect(vm1.$el.innerHTML.includes('This issue is confidential')).toBe(true);

    expect(vm2.$el.innerHTML.includes('Not confidential')).toBe(true);
  });

  it('displays the edit form when editable', () => {
    expect(vm1.edit).toBe(false);

    vm1.$el.querySelector('.confidential-edit').click();

    expect(vm1.edit).toBe(true);

    return Vue.nextTick().then(() => {
      expect(vm1.$el.innerHTML.includes('You are going to turn off the confidentiality.')).toBe(
        true,
      );
    });
  });

  it('displays the edit form when opened from collapsed state', () => {
    expect(vm1.edit).toBe(false);

    vm1.$el.querySelector('.sidebar-collapsed-icon').click();

    expect(vm1.edit).toBe(true);

    return Vue.nextTick().then(() => {
      expect(vm1.$el.innerHTML.includes('You are going to turn off the confidentiality.')).toBe(
        true,
      );
    });
  });

  it('tracks the event when "Edit" is clicked', () => {
    const spy = mockTracking('_category_', vm1.$el, jest.spyOn);
    triggerEvent('.confidential-edit');

    expect(spy).toHaveBeenCalledWith('_category_', 'click_edit_button', {
      label: 'right_sidebar',
      property: 'confidentiality',
    });
  });
});

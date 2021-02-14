import { mount } from '@vue/test-utils';
import DatePicker from '~/vue_shared/components/pikaday.vue';
import SidebarDatePicker from '~/vue_shared/components/sidebar/date_picker.vue';

describe('SidebarDatePicker', () => {
  let wrapper;

  const mountComponent = (propsData = {}, data = {}) => {
    if (wrapper) {
      throw new Error('tried to call mountComponent without d');
    }
    wrapper = mount(SidebarDatePicker, {
      stubs: {
        DatePicker: true,
      },
      propsData,
      data: () => data,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should emit toggleCollapse when collapsed toggle sidebar is clicked', () => {
    mountComponent();

    wrapper.find('.issuable-sidebar-header .gutter-toggle').element.click();

    expect(wrapper.emitted('toggleCollapse')).toEqual([[]]);
  });

  it('should render collapsed-calendar-icon', () => {
    mountComponent();

    expect(wrapper.find('.sidebar-collapsed-icon').element).toBeDefined();
  });

  it('should render value when not editing', () => {
    mountComponent();

    expect(wrapper.find('.value-content').element).toBeDefined();
  });

  it('should render None if there is no selectedDate', () => {
    mountComponent();

    expect(wrapper.find('.value-content span').text().trim()).toEqual('None');
  });

  it('should render date-picker when editing', () => {
    mountComponent({}, { editing: true });

    expect(wrapper.find(DatePicker).element).toBeDefined();
  });

  it('should render label', () => {
    const label = 'label';
    mountComponent({ label });
    expect(wrapper.find('.title').text().trim()).toEqual(label);
  });

  it('should render loading-icon when isLoading', () => {
    mountComponent({ isLoading: true });
    expect(wrapper.find('.gl-spinner').element).toBeDefined();
  });

  describe('editable', () => {
    beforeEach(() => {
      mountComponent({ editable: true });
    });

    it('should render edit button', () => {
      expect(wrapper.find('.title .btn-blank').text().trim()).toEqual('Edit');
    });

    it('should enable editing when edit button is clicked', async () => {
      wrapper.find('.title .btn-blank').element.click();

      await wrapper.vm.$nextTick();

      expect(wrapper.vm.editing).toEqual(true);
    });
  });

  it('should render date if selectedDate', () => {
    mountComponent({ selectedDate: new Date('07/07/2017') });

    expect(wrapper.find('.value-content strong').text().trim()).toEqual('Jul 7, 2017');
  });

  describe('selectedDate and editable', () => {
    beforeEach(() => {
      mountComponent({ selectedDate: new Date('07/07/2017'), editable: true });
    });

    it('should render remove button if selectedDate and editable', () => {
      expect(wrapper.find('.value-content .btn-blank').text().trim()).toEqual('remove');
    });

    it('should emit saveDate with null when remove button is clicked', () => {
      wrapper.find('.value-content .btn-blank').element.click();

      expect(wrapper.emitted('saveDate')).toEqual([[null]]);
    });
  });

  describe('showToggleSidebar', () => {
    beforeEach(() => {
      mountComponent({ showToggleSidebar: true });
    });

    it('should render toggle-sidebar when showToggleSidebar', () => {
      expect(wrapper.find('.title .gutter-toggle').element).toBeDefined();
    });

    it('should emit toggleCollapse when toggle sidebar is clicked', () => {
      wrapper.find('.title .gutter-toggle').element.click();

      expect(wrapper.emitted('toggleCollapse')).toEqual([[]]);
    });
  });
});

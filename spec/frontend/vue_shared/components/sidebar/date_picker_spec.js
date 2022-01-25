import { GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DatePicker from '~/vue_shared/components/pikaday.vue';
import SidebarDatePicker from '~/vue_shared/components/sidebar/date_picker.vue';

describe('SidebarDatePicker', () => {
  let wrapper;

  const createComponent = (propsData = {}, data = {}) => {
    wrapper = mount(SidebarDatePicker, {
      propsData,
      data: () => data,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findDatePicker = () => wrapper.findComponent(DatePicker);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEditButton = () => wrapper.find('.title .btn-blank');
  const findRemoveButton = () => wrapper.find('.value-content .btn-blank');
  const findSidebarToggle = () => wrapper.find('.title .gutter-toggle');
  const findValueContent = () => wrapper.find('.value-content');

  it('should emit toggleCollapse when collapsed toggle sidebar is clicked', () => {
    createComponent();

    wrapper.find('.issuable-sidebar-header .gutter-toggle').trigger('click');

    expect(wrapper.emitted('toggleCollapse')).toEqual([[]]);
  });

  it('should render collapsed-calendar-icon', () => {
    createComponent();

    expect(wrapper.find('.sidebar-collapsed-icon').exists()).toBe(true);
  });

  it('should render value when not editing', () => {
    createComponent();

    expect(findValueContent().exists()).toBe(true);
  });

  it('should render None if there is no selectedDate', () => {
    createComponent();

    expect(findValueContent().text()).toBe('None');
  });

  it('should render date-picker when editing', () => {
    createComponent({}, { editing: true });

    expect(findDatePicker().exists()).toBe(true);
  });

  it('should render label', () => {
    const label = 'label';
    createComponent({ label });
    expect(wrapper.find('.title').text()).toBe(label);
  });

  it('should render loading-icon when isLoading', () => {
    createComponent({ isLoading: true });
    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('editable', () => {
    beforeEach(() => {
      createComponent({ editable: true });
    });

    it('should render edit button', () => {
      expect(findEditButton().text()).toBe('Edit');
    });

    it('should enable editing when edit button is clicked', async () => {
      findEditButton().trigger('click');

      await nextTick();

      expect(wrapper.vm.editing).toBe(true);
    });
  });

  it('should render date if selectedDate', () => {
    createComponent({ selectedDate: new Date('07/07/2017') });

    expect(wrapper.find('.value-content strong').text()).toBe('Jul 7, 2017');
  });

  describe('selectedDate and editable', () => {
    beforeEach(() => {
      createComponent({ selectedDate: new Date('07/07/2017'), editable: true });
    });

    it('should render remove button if selectedDate and editable', () => {
      expect(findRemoveButton().text()).toBe('remove');
    });

    it('should emit saveDate with null when remove button is clicked', () => {
      findRemoveButton().trigger('click');

      expect(wrapper.emitted('saveDate')).toEqual([[null]]);
    });
  });

  describe('showToggleSidebar', () => {
    beforeEach(() => {
      createComponent({ showToggleSidebar: true });
    });

    it('should render toggle-sidebar when showToggleSidebar', () => {
      expect(findSidebarToggle().exists()).toBe(true);
    });

    it('should emit toggleCollapse when toggle sidebar is clicked', () => {
      findSidebarToggle().trigger('click');

      expect(wrapper.emitted('toggleCollapse')).toEqual([[]]);
    });
  });
});

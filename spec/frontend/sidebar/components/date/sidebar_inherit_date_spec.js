import { GlFormRadio } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SidebarFormattedDate from '~/sidebar/components/date/sidebar_formatted_date.vue';
import SidebarInheritDate from '~/sidebar/components/date/sidebar_inherit_date.vue';

describe('SidebarInheritDate', () => {
  let wrapper;
  const findFixedFormattedDate = () => wrapper.findAll(SidebarFormattedDate).at(0);
  const findInheritFormattedDate = () => wrapper.findAll(SidebarFormattedDate).at(1);
  const findFixedRadio = () => wrapper.findAll(GlFormRadio).at(0);
  const findInheritRadio = () => wrapper.findAll(GlFormRadio).at(1);

  const createComponent = () => {
    wrapper = shallowMount(SidebarInheritDate, {
      provide: {
        canUpdate: true,
      },
      propsData: {
        issuable: {
          dueDate: '2021-04-15',
          dueDateIsFixed: true,
          dueDateFixed: '2021-04-15',
          dueDateFromMilestones: '2021-05-15',
        },
        isLoading: false,
        dateType: 'dueDate',
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays formatted fixed and inherited dates with radio buttons', () => {
    expect(wrapper.findAll(SidebarFormattedDate)).toHaveLength(2);
    expect(wrapper.findAll(GlFormRadio)).toHaveLength(2);
    expect(findFixedFormattedDate().props('formattedDate')).toBe('Apr 15, 2021');
    expect(findInheritFormattedDate().props('formattedDate')).toBe('May 15, 2021');
    expect(findFixedRadio().text()).toBe('Fixed:');
    expect(findInheritRadio().text()).toBe('Inherited:');
  });

  it('emits set-date event on click on radio button', () => {
    findFixedRadio().vm.$emit('input', true);

    expect(wrapper.emitted('set-date')).toEqual([[true]]);
  });
});

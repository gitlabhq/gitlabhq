import { GlFormRadio } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SidebarFormattedDate from '~/sidebar/components/date/sidebar_formatted_date.vue';
import SidebarInheritDate from '~/sidebar/components/date/sidebar_inherit_date.vue';

describe('SidebarInheritDate', () => {
  let wrapper;
  const findFixedFormattedDate = () => wrapper.findAllComponents(SidebarFormattedDate).at(0);
  const findInheritFormattedDate = () => wrapper.findAllComponents(SidebarFormattedDate).at(1);
  const findFixedRadio = () => wrapper.findAllComponents(GlFormRadio).at(0);
  const findInheritRadio = () => wrapper.findAllComponents(GlFormRadio).at(1);

  const createComponent = ({ dueDateIsFixed = false } = {}) => {
    wrapper = shallowMount(SidebarInheritDate, {
      provide: {
        canUpdate: true,
      },
      propsData: {
        issuable: {
          dueDate: '2021-04-15',
          dueDateIsFixed,
          dueDateFixed: '2021-04-15',
          dueDateFromMilestones: '2021-05-15',
        },
        dateType: 'dueDate',
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('displays formatted fixed and inherited dates with radio buttons', () => {
    expect(wrapper.findAllComponents(SidebarFormattedDate)).toHaveLength(2);
    expect(wrapper.findAllComponents(GlFormRadio)).toHaveLength(2);
    expect(findFixedFormattedDate().props('formattedDate')).toBe('Apr 15, 2021');
    expect(findInheritFormattedDate().props('formattedDate')).toBe('May 15, 2021');
    expect(findFixedRadio().text()).toBe('Fixed:');
    expect(findInheritRadio().text()).toBe('Inherited:');
  });

  it('does not emit set-date if fixed value does not change', () => {
    createComponent({ dueDateIsFixed: true });
    findFixedRadio().vm.$emit('input', true);

    expect(wrapper.emitted('set-date')).toBeUndefined();
  });

  it('emits set-date event on click on radio button', () => {
    findFixedRadio().vm.$emit('input', true);

    expect(wrapper.emitted('set-date')).toEqual([[true]]);
  });
});

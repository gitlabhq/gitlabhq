import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SidebarFormattedDate from '~/sidebar/components/date/sidebar_formatted_date.vue';

describe('SidebarFormattedDate', () => {
  let wrapper;
  const findFormattedDate = () => wrapper.find("[data-testid='sidebar-date-value']");
  const findRemoveButton = () => wrapper.findComponent(GlButton);

  const createComponent = ({ hasDate = true } = {}) => {
    wrapper = shallowMount(SidebarFormattedDate, {
      provide: {
        canUpdate: true,
      },
      propsData: {
        formattedDate: 'Apr 15, 2021',
        hasDate,
        issuableType: 'issue',
        resetText: 'remove',
        isLoading: false,
        canDelete: true,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('displays formatted date', () => {
    expect(findFormattedDate().text()).toBe('Apr 15, 2021');
  });

  describe('when issue has due date', () => {
    it('displays remove button', () => {
      expect(findRemoveButton().exists()).toBe(true);
      expect(findRemoveButton().children).toEqual(wrapper.props.resetText);
    });

    it('emits reset-date event on click on remove button', () => {
      findRemoveButton().vm.$emit('click');

      expect(wrapper.emitted('reset-date')).toEqual([[undefined]]);
    });
  });

  describe('when issuable has no due date', () => {
    beforeEach(() => {
      createComponent({
        hasDate: false,
      });
    });

    it('does not display remove button', () => {
      expect(findRemoveButton().exists()).toBe(false);
    });
  });
});

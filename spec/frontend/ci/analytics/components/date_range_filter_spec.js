import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DateRangeFilter from '~/ci/analytics/components/date_range_filter.vue';

describe('DateRangeFilter', () => {
  let wrapper;

  const findCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  const createComponent = ({ props, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(DateRangeFilter, {
      propsData: {
        id: 'my-id',
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('shows options', () => {
    const ranges = findCollapsibleListbox()
      .props('items')
      .map(({ text }) => text);

    expect(ranges).toEqual(['Last week', 'Last 30 days', 'Last 90 days', 'Last 180 days']);
  });

  it('is "Last 7 days" by default', () => {
    expect(findCollapsibleListbox().props('selected')).toBe('7d');
  });

  it('does not set invalid value as selected', () => {
    createComponent({
      props: {
        selected: 'NOT_AN_OPTION',
      },
    });

    expect(findCollapsibleListbox().props('selected')).toBe('7d');
  });

  describe('when an option is selected', () => {
    beforeEach(async () => {
      findCollapsibleListbox().vm.$emit('select', '90d');
      await nextTick();
    });

    it('emits selection', () => {
      expect(wrapper.emitted('select')[0][0]).toEqual('90d');
    });

    it('display range', () => {
      expect(wrapper.text()).toEqual('Apr 7 – Jul 6, 2020');
    });
  });
});

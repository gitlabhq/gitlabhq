import { GlDatepicker, GlFilteredSearchToken } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import DateToken from '~/vue_shared/components/filtered_search_bar/tokens/date_token.vue';

const propsData = {
  active: true,
  config: {},
  value: { operator: '>', data: null },
};

function createComponent() {
  return mount(DateToken, {
    propsData,
    provide: {
      portalName: 'fake target',
      alignSuggestions: function fakeAlignSuggestions() {},
      termsAsTokens: () => false,
    },
  });
}

describe('DateToken', () => {
  let wrapper;

  const findGlFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchToken);
  const findDatepicker = () => wrapper.findComponent(GlDatepicker);

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('renders GlDatepicker', () => {
    expect(findDatepicker().exists()).toBe(true);
  });

  it('renders GlFilteredSearchToken', () => {
    expect(findGlFilteredSearchToken().exists()).toBe(true);
  });

  it('emits `complete` and `select` with the formatted date when a value is selected', () => {
    findDatepicker().vm.$emit('input', new Date('October 13, 2014 11:13:00'));
    findDatepicker().vm.$emit('close');

    expect(findGlFilteredSearchToken().emitted()).toEqual({
      complete: [['2014-10-13']],
      select: [['2014-10-13']],
    });
  });
});
